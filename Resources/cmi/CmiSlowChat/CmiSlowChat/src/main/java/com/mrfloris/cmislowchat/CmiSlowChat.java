package com.mrfloris.cmislowchat;

import io.papermc.paper.event.player.AsyncChatEvent;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public class CmiSlowChat extends JavaPlugin implements Listener {

    private final Map<UUID, Long> lastChat = new ConcurrentHashMap<>();
    private boolean cmiPresent;
    private long cooldownMillis;
    private boolean useCmiMute;
    private String cmiMuteDuration;
    private String cmiMuteReason;

    @Override
    public void onEnable() {
        saveDefaultConfig();

        cooldownMillis = getConfig().getLong("cooldown-seconds", 3L) * 1000L;
        if (cooldownMillis < 0L) {
            cooldownMillis = 0L;
        }

        useCmiMute = getConfig().getBoolean("use-cmi-mute", false);
        cmiMuteDuration = getConfig().getString("cmi-mute-duration", "3s");
        cmiMuteReason = getConfig().getString("cmi-mute-reason", "&7Slow chat is enabled; please wait before chatting again.");

        cmiPresent = Bukkit.getPluginManager().getPlugin("CMI") != null;

        getServer().getPluginManager().registerEvents(this, this);

        getLogger().info("CmiSlowChat enabled. Cooldown = " + (cooldownMillis / 1000) + "s, CMI present: " + cmiPresent);
    }

    @Override
    public void onDisable() {
        lastChat.clear();
    }

    @EventHandler(ignoreCancelled = true, priority = EventPriority.HIGHEST)
    public void onAsyncChat(AsyncChatEvent event) {
        Player player = event.getPlayer();

        if (cooldownMillis <= 0) {
            return; // disabled
        }

        if (player.hasPermission("cmi.slowchat.bypass")) {
            return; // bypass
        }

        long now = System.currentTimeMillis();
        UUID uuid = player.getUniqueId();
        long last = lastChat.getOrDefault(uuid, 0L);
        long diff = now - last;

        if (diff < cooldownMillis) {
            long remainingMs = cooldownMillis - diff;
            long remainingSec = (remainingMs + 999) / 1000; // ceil

            player.sendMessage("§cSlow chat is enabled. Please wait §e" + remainingSec + "§c second"
                    + (remainingSec == 1 ? "" : "s") + " before chatting again.");
            event.setCancelled(true);

            if (useCmiMute && cmiPresent) {
                Bukkit.getScheduler().runTask(this, () -> {
                    String cmd = "cmi mute " + player.getName() + " " + cmiMuteDuration + " " + cmiMuteReason;
                    Bukkit.dispatchCommand(Bukkit.getConsoleSender(), cmd);
                });
            }
            return;
        }

        lastChat.put(uuid, now);
    }
}
