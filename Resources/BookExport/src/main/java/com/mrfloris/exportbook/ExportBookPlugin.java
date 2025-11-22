package com.mrfloris.exportbook;

import org.bukkit.ChatColor;
import org.bukkit.Material;
import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.inventory.ItemStack;
import org.bukkit.inventory.meta.BookMeta;
import org.bukkit.plugin.java.JavaPlugin;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

public class ExportBookPlugin extends JavaPlugin {

    private File exportFolder;

    @Override
    public void onEnable() {
        // Ensure config exists
        saveDefaultConfig();

        // Determine export folder based on config
        exportFolder = resolveExportFolder();

        if (!exportFolder.exists() && exportFolder.mkdirs()) {
            getLogger().info("Created export folder: " + exportFolder.getPath());
        }

        getLogger().info("BookExport enabled. Export folder: " + exportFolder.getPath());
    }

    private File resolveExportFolder() {
        File dataFolder = getDataFolder(); // plugins/BookExport
        String dirSetting = getConfig().getString("exported-books-directory", "books");

        if (dirSetting == null || dirSetting.trim().isEmpty()) {
            return dataFolder;
        }

        String s = dirSetting.trim();

        // "~/something" -> relative to server root
        if (s.startsWith("~/")) {
            // serverRoot = plugins/.. (the folder that contains "plugins")
            File serverRoot = dataFolder.getParentFile() != null
                    ? dataFolder.getParentFile().getParentFile()
                    : dataFolder.getParentFile();
            if (serverRoot == null) {
                serverRoot = new File(".").getAbsoluteFile();
            }
            String subPath = s.substring(2); // remove "~/"
            return new File(serverRoot, subPath);
        }

        // Absolute path (Unix) or Windows drive path
        if (s.startsWith("/") || s.matches("^[A-Za-z]:\\.*")) {
            return new File(s);
        }

        // Relative path -> inside plugin data folder
        return new File(dataFolder, s);
    }

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (!command.getName().equalsIgnoreCase("bookexport")) {
            return false;
        }

        // Subcommands that can be run from console too:
        if (args.length > 0) {
            String sub = args[0].toLowerCase();

            if (sub.equals("reload")) {
                if (!sender.hasPermission("exportbook.reload")) {
                    sender.sendMessage(ChatColor.RED + "You don't have permission to reload the config.");
                    return true;
                }
                reloadConfig();
                // Re-resolve export folder in case the path changed
                exportFolder = resolveExportFolder();
                if (!exportFolder.exists()) {
                    exportFolder.mkdirs();
                }
                sender.sendMessage(ChatColor.GREEN + "BookExport configuration reloaded.");
                return true;
            }

            if (sub.equals("help")) {
                sendHelp(sender);
                return true;
            }

            if (sub.equals("list")) {
                listExports(sender);
                return true;
            }
        }

        if (!(sender instanceof Player)) {
            sender.sendMessage(ChatColor.RED + "Only players can export books.");
            return true;
        }

        Player player = (Player) sender;

        if (!player.hasPermission("exportbook.command")) {
            player.sendMessage(ChatColor.RED + "You don't have permission to use this command.");
            return true;
        }

        ItemStack inHand = player.getInventory().getItemInMainHand();
        if (inHand == null || (inHand.getType() != Material.WRITTEN_BOOK
                && inHand.getType() != Material.WRITABLE_BOOK)) {
            player.sendMessage(ChatColor.RED + "You must hold a written book or book & quill in your main hand.");
            return true;
        }

        if (!(inHand.getItemMeta() instanceof BookMeta bookMeta)) {
            player.sendMessage(ChatColor.RED + "This item doesn't seem to be a valid book.");
            return true;
        }

        List<String> pages = bookMeta.getPages();
        if (pages.isEmpty()) {
            player.sendMessage(ChatColor.RED + "This book has no pages to export.");
            return true;
        }

        // Determine raw title: either argument(s) or the book's title when no args
        String rawTitle;
        if (args.length == 0) {
            String bookTitle = bookMeta.getTitle();
            if (bookTitle == null || bookTitle.isBlank()) {
                // For book & quill with no title: show help instead
                if (inHand.getType() == Material.WRITABLE_BOOK) {
                    sendHelp(player);
                } else {
                    player.sendMessage(ChatColor.RED + "This book has no title. Please use /bookexport <title>.");
                }
                return true;
            }
            rawTitle = bookTitle;
        } else {
            // If the first arg was 'help', 'reload' or 'list', we'd have returned earlier.
            rawTitle = String.join(" ", args).trim();
        }

        if (rawTitle.isEmpty()) {
            player.sendMessage(ChatColor.RED + "Please provide a file title.");
            return true;
        }

        // Sanitize title for file name
        String safeTitle = rawTitle
                .replaceAll("[^a-zA-Z0-9_ -]", "")
                .replace(' ', '_');

        if (safeTitle.isEmpty()) {
            player.sendMessage(ChatColor.RED + "That title cannot be used as a file name.");
            return true;
        }

        // Config options
        boolean pagination = getConfig().getBoolean("pagination", true);
        String paginationMarkup = getConfig().getString("pagination-markup", "=== Page %pageNumber% ===");
        if (paginationMarkup == null || paginationMarkup.isEmpty()) {
            paginationMarkup = "=== Page %pageNumber% ===";
        }
        boolean includeMeta = getConfig().getBoolean("book-meta", true);

        // Build text content
        StringBuilder sb = new StringBuilder();

        // Optional header
        String bookTitle = bookMeta.getTitle() != null ? bookMeta.getTitle() : "Untitled Book";
        String author = bookMeta.getAuthor() != null ? bookMeta.getAuthor() : "Unknown";

        if (includeMeta) {
            sb.append("Title: ").append(bookTitle).append(System.lineSeparator());
            sb.append("Author: ").append(author).append(System.lineSeparator());
            sb.append("Exported by: ").append(player.getName()).append(System.lineSeparator());
            sb.append("Exported at: ").append(
                    LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            ).append(System.lineSeparator());
            sb.append(System.lineSeparator());
        }

        // Dump pages
        for (int i = 0; i < pages.size(); i++) {
            int pageNumber = i + 1;

            if (pagination) {
                String paginationLine = paginationMarkup.replace("%pageNumber%", String.valueOf(pageNumber));
                sb.append(paginationLine).append(System.lineSeparator());
            }

            sb.append(pages.get(i))
              .append(System.lineSeparator())
              .append(System.lineSeparator());
        }

        // Ensure folder exists
        if (!exportFolder.exists() && !exportFolder.mkdirs()) {
            player.sendMessage(ChatColor.RED + "Failed to create export folder. Check server logs.");
            return true;
        }

        // Base filename (no plugin version in the name)
        String baseName = safeTitle;

        // Handle file collisions by appending a number
        File outFile = new File(exportFolder, baseName + ".txt");
        int counter = 1;
        while (outFile.exists()) {
            outFile = new File(exportFolder, baseName + "_" + counter + ".txt");
            counter++;
        }

        try {
            Files.writeString(outFile.toPath(), sb.toString(), StandardCharsets.UTF_8);
            player.sendMessage(ChatColor.GREEN + "Book exported to: "
                    + ChatColor.YELLOW + outFile.getPath());
        } catch (IOException e) {
            player.sendMessage(ChatColor.RED + "Failed to export book. Check server console for details.");
            getLogger().severe("Error exporting book:");
            e.printStackTrace();
        }

        return true;
    }

    private void listExports(CommandSender sender) {
        if (!exportFolder.exists() || !exportFolder.isDirectory()) {
            sender.sendMessage(ChatColor.RED + "Export folder does not exist: " + exportFolder.getPath());
            return;
        }

        FilenameFilter txtFilter = (dir, name) -> name.toLowerCase().endsWith(".txt");
        File[] files = exportFolder.listFiles(txtFilter);

        if (files == null || files.length == 0) {
            sender.sendMessage(ChatColor.YELLOW + "No exported book files found in:");
            sender.sendMessage(ChatColor.GRAY + "  " + exportFolder.getPath());
            return;
        }

        Arrays.sort(files, Comparator.comparing(File::getName, String.CASE_INSENSITIVE_ORDER));

        sender.sendMessage(ChatColor.GOLD + "Exported book files (" + files.length + "):");
        for (File file : files) {
            sender.sendMessage(ChatColor.GRAY + " - " + file.getName());
        }
    }

    private void sendHelp(CommandSender sender) {
        sender.sendMessage(ChatColor.GOLD + "BookExport " + ChatColor.YELLOW + "- by mrfloris");
        sender.sendMessage(ChatColor.YELLOW + "/bookexport <title> " + ChatColor.GRAY + "- Export the book in your main hand using a custom title.");
        sender.sendMessage(ChatColor.YELLOW + "/bookexport " + ChatColor.GRAY + "- Export the book using its signed title (written books only).");
        sender.sendMessage(ChatColor.YELLOW + "/bookexport list " + ChatColor.GRAY + "- List exported .txt files in the configured folder.");
        sender.sendMessage(ChatColor.YELLOW + "/bookexport reload " + ChatColor.GRAY + "- Reload the configuration.");
        sender.sendMessage(ChatColor.YELLOW + "/bookexport help " + ChatColor.GRAY + "- Show this help page.");
        sender.sendMessage(ChatColor.GRAY + "Config options: pagination, pagination-markup, book-meta, exported-books-directory");
    }
}
