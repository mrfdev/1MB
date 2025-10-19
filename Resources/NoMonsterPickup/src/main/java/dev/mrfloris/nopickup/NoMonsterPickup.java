package dev.mrfloris.nopickup;

import org.bukkit.entity.Monster;
import org.bukkit.entity.Piglin;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.EntityPickupItemEvent;
import org.bukkit.plugin.java.JavaPlugin;

/**
 * NoMonsterPickup v1.1.0
 * Paper 1.21.8
 * 
 * Prevents all Monster entities from picking up items,
 * EXCEPT regular Piglins (to preserve bartering).
 * Piglin Brutes and Zombified Piglins remain blocked.
 * Credit goes to Killian for sharing base code lines
 */
public final class NoMonsterPickup extends JavaPlugin implements Listener {

    @Override
    public void onEnable() {
        getServer().getPluginManager().registerEvents(this, this);
        getLogger().info("NoMonsterPickup 1.1.0 enabled: blocking monster item pickups (Piglins allowed).");
    }

    @EventHandler(ignoreCancelled = true)
    public void onEntityPickupItem(EntityPickupItemEvent e) {
        // If it's not a Monster at all, ignore.
        if (!(e.getEntity() instanceof Monster)) {
            return;
        }
        // Allow regular Piglins (bartering).
        if (e.getEntity() instanceof Piglin) {
            return;
        }
        // Block everyone else that is a Monster.
        e.setCancelled(true);
    }
}