# mcMMO Mining

Mining is a non-combat skill centred around breaking blocks with a pickaxe.


## Experience gain

Experience in Mining is gained by breaking naturally generated blocks with a pickaxe, and exploding ore via Blast Mining. These blocks include but are not limited to ore, stone, and even Purpur bricks found in End cities. Each block has its own experience value, and can be changed within the configuration files.

## Super ability

### Super Breaker

The Super Breaker ability is activated by right clicking on any block that can yield experience and then left clicking on said block. Doing either on a block which is not defined in the configuration (such as cobblestone or dirt) will not trigger the ability, and will not ready the ability. That said, you may add any blocks you wish.

When activated, Super Breaker will apply an additive +5 rank Efficiency enchantment to your currently held pickaxe and give you a chance at triple drops. E.g., if your pickaxe currently has Efficiency 5, activating Super Breaker will give you Efficiency 10 for the duration of the ability.

The duration of Super Breaker increases by 1 second every 50 (5 normal) levels, and starts at 2 seconds at level 1.

## SubSkills

### Blast Mining

Note: 1MB server does not have blast mining turned on.

Blast Mining allows you to use TNT to mine ore, without a risk of losing any of the ore. There's a few catches, though - it has a 60 second cooldown, and the TNT cannot be lit normally. To activate Blast Mining and simultaneously trigger the TNT, you need to move out of the 'block selection' range and then shift right click with the crosshair pointed at the TNT you placed. This will instantly trigger an explosion, rather than causing it to flash.

The benefits of using Blast Mining are a chance at triple drops, and guaranteed silk-touched ore. As you rank up your Blast Mining, you can also reduce the debris that drop (such as cobble) to almost nothing, as well as increase the blast radius of the explosion through the Bigger Bombs passive sub-skill. There's also a damage reduction from TNT explosions, via the Demolitions Expertise passive sub-skill.

Below: Passive sub-skills

### Double Drops

The Double Drops passive sub-skill provides a chance for naturally generated blocks you break with your pickaxe to turn into two blocks.

Please do note that this sub-skill's doubling effect only happens upon the initial mining of the ore; you will not receive double the ore again after it has been placed by a player. Meaning, only vanilla's fortune effect will apply to ores mined after being placed by a player.

### Bigger Bombs

Unlocking Bigger Bombs extends the radius of your Blast Mining explosions.

### Demolitions Expertise

Demolitions Expertise reduces the damage you take from TNT explosions.

### Flux Mining

Removed.




## Commands XPGain Mining

```
Mining Stone & Ore
```



#MINING
## Mining Ability Locked 0

```
LOCKED UNTIL x+ SKILL (BLAST MINING)
```

## Mining Ability Locked 1

```
LOCKED UNTIL x+ SKILL (BIGGER BOMBS)
```

## Mining Ability Locked 2

```
LOCKED UNTIL x+ SKILL (DEMOLITIONS EXPERTISE)
```

## Mining Ability Lower

```
You lower your Pickaxe.
```

## Mining Ability Ready

```
You ready your pickaxe.
```

## Mining SubSkill SuperBreaker Name

```
Super Breaker
```

## Mining SubSkill SuperBreaker Description

```
Speed+, Triple Drop Chance
```

## Mining SubSkill SuperBreaker Stat

```
Super Breaker Length
```

## Mining SubSkill DoubleDrops Name

```
Double Drops
```

## Mining SubSkill DoubleDrops Description

```
Double the normal loot
```

## Mining SubSkill DoubleDrops Stat

```
Double Drop Chance
```

## Mining SubSkill BlastMining Name

```
Blast Mining
```

## Mining SubSkill BlastMining Description

```
Bonuses to mining with TNT
```

## Mining SubSkill BlastMining Stat

```
Blast Mining: Rank x/x (x)
```

## Mining.SubSkill BlastMining Stat Extra

```
Blast Radius Increase: +x
```

## Mining SubSkill BiggerBombs Name

```
Bigger Bombs
```

## Mining SubSkill BiggerBombs Description

```
Increases TNT explosion radius
```

## Mining SubSkill DemolitionsExpertise Name

```
Demolitions Expertise
```

## Mining SubSkill DemolitionsExpertise Description

```
Decreases damage from TNT explosions
```

## Mining SubSkill DemolitionsExpertise Stat

```
Demolitions Expert Damage Decrease
```


## Mining Listener

```
Mining:
```

## Mining SkillName

```
MINING
```

## Mining Skills SuperBreaker Off

```
**Super Breaker has worn off**
```

## Mining Skills SuperBreaker On

```
**SUPER BREAKER ACTIVATED**
```

## Mining.Skills SuperBreaker Other Off

```
Super Breaker has worn off for x
```

## Mining.Skills SuperBreaker Other On

```
x has used Super Breaker!
```

## Mining Skills SuperBreaker Refresh

```
Your Super Breaker ability is refreshed!
```

#Blast Mining
## Mining Blast Boom

```
**BOOM**
```

## Mining Blast Cooldown

```
x
```

## Mining Blast Effect

```
+x ore yield,  xx drops
```

## Mining Blast Other On

```
x has used Blast Mining!
```

## Mining Blast Refresh

```
Your Blast Mining ability is refreshed!
```


##Mining
## Guides Mining Section 0

```
About Mining:
Mining consists of mining stone and ores. It provides bonuses
to the amount of materials dropped while mining.

XP GAIN:
To gain XP in this skill, you must mine with a pickaxe in hand.
Only certain blocks award XP.
```

## Guides Mining Section 1

```
Compatible Materials:
Stone, Coal Ore, Iron Ore, Gold Ore, Diamond Ore, Redstone Ore,
Lapis Ore, Obsidian, Mossy Cobblestone, Ender Stone,
Glowstone, and Netherrack.
```

## Guides Mining Section 2

```
How to use Super Breaker:
With a pickaxe in your hand, right click to ready your tool.
Once in this state, you have about 4 seconds to make contact
with Mining compatible materials, which will activate Super
Breaker.
```

## Guides Mining Section 3

```
What is Super Breaker?
Super Breaker is an ability with a cooldown tied to the Mining
skill. It triples your chance of extra items dropping and
enables instant break on Mining materials.
```

## Guides Mining Section 4

```
How to use Blast Mining:
With a pickaxe in hand,
crouch and right-click on TNT from a distance. This will cause the TNT
to instantly explode.
```

## Guides Mining Section 5

```
How does Blast Mining work?
Blast Mining is an ability with a cooldown tied to the Mining
skill. It gives bonuses when mining with TNT and allows you
to remote detonate TNT. There are three parts to Blast Mining.
The first part is Bigger Bombs, which increases blast radius.
The second is Demolitions Expert, which decreases damage
from TNT explosions. The third part simply increases the
amount of ores dropped from TNT and decreases the
debris dropped.
```

https://mcmmo.org/wiki/Mining
