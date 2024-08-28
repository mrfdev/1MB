# mcMMO Unarmed

Unarmed is a combat skill which allows players to use their fists as if they were a proper weapon.


## Experience gain

Experience in Unarmed is gained by dealing damage with your fists to mobs, or players.

The experience gained is based on how much damage you deal to a mob, or player. In addition to this, each mob has its own experience multiplier, which can be changed within the configuration files.


## Super ability

### Berserk

The Berserk ability is activated by right clicking with no items equipped, whilst you have a block or mob 'selected' in your crosshairs and then left clicking. Clicking when your crosshairs are aimed at something yet not selected (e.g., a faraway block) will not trigger the ability, nor ready the ability.

When activated, Berserk has a few benefits. Firstly, if you left click on stone bricks they will change into cracked stone bricks. Secondly, blocks with no blast resistance (leaves, grass blocks, dirt, etc.) will break much faster with your bare hands. Thirdly, you receive a +50% damage boost on top of your current level's damage boost.

The duration of Berserk increases by 1 second every 50 (5 normal) levels, and starts at 2 seconds at level 1.


## SubSkills

### Arrow Deflect

The Arrow Deflect passive sub-skill provides a chance to both deflect an arrow, and cause said arrow to ricochet back and hit your attacker. The chance to cause an arrow to be flung back at your attacker is much lower than that of a normal deflect.

When this sub-skill unlocks at level 200 (20 standard), it only has one rank but the chance to deflect continues to increase every 100 (10 normal) levels.

### Disarm

The Disarm passive sub-skill provides a chance to disarm your opponent in a pvp fight. This has no effect in pve; e.g., you cannot disarm a skeleton. This sub-skill can cause a player to drop anything currently held in their main hand, from blocks, to food, to weapons. Said item will drop on the ground, where you or your opponent will have a chance to pick it up.

This sub-skill has a maximum chance of 33%, which is attained at level 1000 (100 normal). It is unlocked at level 250 (25 normal).

### Iron Arm Style

The Iron Arm Style passive sub-skill provides extra damage to mobs and players you attack with your bare hands, which increases based on your Iron Arm Style rank. By default, this sub-skill adds +4 damage (2 hearts) at rank 1. Note that this is raw damage, prior to armour calculation - think of it like the +4 damage displayed on a wooden sword. Your rank increases at a configurable level threshold.

### Iron Grip

The Iron Grip passive sub-skill which exists solely to provide you with a chance to negate another player's Disarm skill. Iron grip has a 100% chance at level 1000 (100 normal), which will effectively make it impossible for you to be disarmed.

This sub-skill is unlocked at level 600 (60 normal) and starts with a 60% chance to not be disarmed. It increases by 1%, every 10 (1 normal) levels.

### Limit Break

The Limit Break sub-skill is intended to make Protection IV players less tanky and for you to feel more powerful for having a high skill level. Limit Break has 10 ranks, each rank gives 1 extra raw damage, this is damage before reductions from armour and enchantments. The net result is you deal about 50% more damage with an end game skill compared to before. At max rank, you can two-hit a player in normal diamond armour, whereas it takes around five hits to kill a player in Protection IV diamond armour.

For PvP, this sub-skill only activates on a player when they have armour equipped. As such, players with no armour will not receive the extra damage. The extra damage is also scaled to what kind of armour the player is wearing. Leather, iron, gold, and chain will only have 25% of your current limit break damage. Diamond will have 50%, and netherite will have 75%. If you enable the "AllowPVE" setting in the "advanced.yml" file, this sub-skill is active at all times. Note that by default, this sub-skill is disabled for PvE.

The limit break sub-skill is unlocked at level 100 (10 normal).


## Commands XPGain Unarmed

```
Attacking Monsters
```



#UNARMED
## Unarmed Ability Bonus 0

```
Steel Arm Style
```

## Unarmed Ability Bonus 1

```
+x DMG Upgrade
```

## Unarmed Ability IronGrip Attacker

```
Your opponent has an iron grip!
```

## Unarmed Ability IronGrip Defender

```
Your iron grip kept you from being disarmed!
```

## Unarmed Ability Lower

```
You lower your fists.
```

## Unarmed Ability Ready

```
You ready your fists.
```

## Unarmed SubSkill Berserk Name

```
Berserk
```

## Unarmed SubSkill Berserk Description

```
+50% DMG, Breaks weak materials
```

## Unarmed SubSkill Berserk Stat

```
Berserk Length
```

## Unarmed SubSkill Disarm Name

```
Disarm
```

## Unarmed SubSkill Disarm Description

```
Drops the foes item held in hand
```

## Unarmed SubSkill Disarm Stat

```
Disarm Chance
```

## Unarmed SubSkill UnarmedLimitBreak Name

```
Unarmed Limit Break
```

## Unarmed SubSkill UnarmedLimitBreak Description

```
Breaking your limits. Increased damage against tough opponents. Intended for PVP, up to server settings for whether or not it will boost damage in PVE.
```

## Unarmed SubSkill UnarmedLimitBreak Stat

```
Limit Break Max DMG
```

## Unarmed SubSkill SteelArmStyle Name

```
Steel Arm Style
```

## Unarmed SubSkill SteelArmStyle Description

```
Hardens your arm over time
```

## Unarmed SubSkill ArrowDeflect Name

```
Arrow Deflect
```

## Unarmed SubSkill ArrowDeflect Description

```
Deflect arrows
```

## Unarmed SubSkill ArrowDeflect Stat

```
Arrow Deflect Chance
```

## Unarmed SubSkill IronGrip Name

```
Iron Grip
```

## Unarmed SubSkill IronGrip Description

```
Prevents you from being disarmed
```

## Unarmed SubSkill IronGrip Stat

```
Iron Grip Chance
```

## Unarmed SubSkill BlockCracker Name

```
Block Cracker
```

## Unarmed SubSkill BlockCracker Description

```
Break rock with your fists
```

## Unarmed Listener

```
Unarmed:
```

## Unarmed SkillName

```
UNARMED
```

## Unarmed Skills Berserk Off

```
**Berserk has worn off**
```

## Unarmed Skills Berserk On

```
**BERSERK ACTIVATED**
```

## Unarmed.Skills Berserk Other Off

```
Berserk has worn off for x
```

## Unarmed.Skills Berserk Other On

```
x has used Berserk!
```

## Unarmed Skills Berserk Refresh

```
Your Berserk ability is refreshed!
```



##Unarmed
## Guides Unarmed Section 0

```
About Unarmed:
Unarmed will give players various combat bonuses when using
your fists as a weapon. 

XP GAIN:
XP is gained based on the amount of damage dealt to mobs 
or other players when unarmed.
```

## Guides Unarmed Section 1

```
How does Berserk work?
Beserk is an active ability that is activated by
right-clicking. While in Beserk mode, you deal 50% more
damage and you can break weak materials instantly, such as
Dirt and Grass.
```

## Guides Unarmed Section 2

```
How does Steel Arm Style work?
Steel Arm Style increases the damage dealt when hitting mobs or
players with your fists.
```

## Guides Unarmed Section 3

```
How does Arrow Deflect work?
Arrow Deflect is a passive ability that gives you a chance
to deflect arrows shot by Skeletons or other players.
The arrow will fall harmlessly to the ground.
```

## Guides Unarmed Section 4

```
How does Iron Grip work?
Iron Grip is a passive ability that counters disarm. As your
unarmed level increases, the chance of preventing a disarm increases.
```

## Guides Unarmed Section 5

```
How does Disarm work?
This passive ability allows players to disarm other players,
causing the target's equipped item to fall to the ground.
```

## Wiki

https://mcmmo.org/wiki/Unarmed


## YOUTUBE

s01e01 - <https://youtu.be/u3TpDapgiYo> ENDERMAN FARM (unarmed and taming)
s01e02 - <https://youtu.be/9MVCXGZcIYo> GUARDIAN GRINDER (combat skills)
s01e03 - <https://youtu.be/MW5i5ro2gnk> POTIONS (brewing)
s01e04 - <https://youtu.be/XVXfNiVSJ7s> SUGARCANE FARM (herbalism)
s01e05 - <https://youtu.be/YEqVI8JysBY> FISHING PARTY (fishing)
s01e06 - <https://youtu.be/rgikQtXI9gY> WOODCUTTING (TREE FARM)
s01e07 - <https://youtu.be/2vk_hLNYga8> MINING / EXCAVATION
s01e08 - <https://youtu.be/8TH3tEbcmT4> ACROBATICS TOWER (feather falling)

