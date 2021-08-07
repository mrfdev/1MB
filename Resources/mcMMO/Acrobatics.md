# mcMMO Acrobatics

Acrobatics is a skill focused around moving gracefully, reducing fall damage and avoiding attacks.

## Experience gain

Experience Gain
Experience in Acrobatics is gained by taking fall damage, successfully rolling on the ground, or successfully dodging attacks.

120XP per half heart of damage is gained when taking fall damage. Assuming no damage is being reduced, it can also be calculated as (b - 3) * 120 where b is the amount of blocks fallen before taking damage. Any reduction of damage by use of hay bales, potions, enchantments etc. will reduce the amount of experience gained. If a roll or graceful roll as been executed, you will gain 80XP per half heart of damage instead of 120XP. This calculation uses the damage that would have been taken if you had not rolled.

Feather falling will double the amount of XP you earn from falling, regardless of its enchantment level. Keep in mind that feather falling will also reduce the amount of base damage dealt when you fall.

Dodging an attack will give 120XP per half heart of damage dodged. So if you dodged an attack that would have dealt you 3 damage, it would give you 360XP.

## Super Ability

Acrobatics does not currently have a super ability.

## Anti exploit

Finding ways to auto acrobatics is not permitted, we have some methods in place to prevent this. If we believe you've auto grinded we will reset your skill.

## Sub SKills

### Rolling

Rolling is an active sub-skill with a passive component. It provides a chance to negate fall damage based on the player's Acrobatics skill level. At level 50, the player has a 50% chance to negate damage, or 100% if Graceful Roll is activated. The chance for success is scaled against the Acrobatics skill level in a linear curve. Every level increases the chance to roll successfully by 1%. Therefore, it will always trigger at level 100.

A normal roll can be transformed into a Graceful Roll by sneaking while falling. Doing so will double the odds to roll and the amount of damage prevented.

### Dodging

Unlocks at Level 2 or Level 20 for Retro Mode

Dodge will give you a chance of reducing incoming damage by half. For instance, if you are receiving 6 damage, you will only receive 3 damage when successfully dodging. You will never dodge an attack if the incoming damage would be lethal, this check is done before dodge reduces incoming damage. Dodge also has a cooldown before it will award XP if the player recently respawned from a death.

Dodge reduces the players damage from various harmful sources. 

## Commands XPGain Acrobatics

```
Falling
```



## JSON.Acrobatics Roll Interaction Activated

```
Test Rolled Test
```

## JSON.Acrobatics.SubSkill Roll Details Tips

```
If you hold sneak while falling you can prevent up to twice the damage that you would normally take!
```


#ACROBATICS
## Acrobatics Ability Proc

```
**Graceful Landing**
```

## Acrobatics Combat Proc

```
**Dodged**
```

## Acrobatics SubSkill Roll Stats

```
Roll Chance x% Graceful Roll Chance x%
```

## Acrobatics SubSkill Roll Stat

```
Roll Chance
```

## Acrobatics.SubSkill Roll Stat Extra

```
Graceful Roll Chance
```

## Acrobatics SubSkill Roll Name

```
Roll
```

## Acrobatics SubSkill Roll Description

```
Land strategically to avoid damage.
```

## Acrobatics SubSkill Roll Chance

```
Roll Chance: x
```

## Acrobatics SubSkill Roll GraceChance

```
Graceful Roll Chance: x
```

## Acrobatics SubSkill Roll Mechanics

```
Rolling is an active Sub-Skill with a passive component.
Whenever you take fall damage you have a chance to completely negate the damage based on your skill level, at level {6}% you have a x% chance to prevent damage, and x% if you activate Graceful Roll.
The chance for success is scaled against your skill level in a linear curve until level x where it maxes out, every level in Acrobatics gives you a x% chance to succeed.
By holding the sneak button you can double your odds to avoid fall damage and avoid up to twice the fall damage! Holding sneak will transform a normal roll into a Graceful Roll.
Rolling will only prevent up to {4} damage. Graceful Rolls will prevent up to {5} damage.
```

## Acrobatics SubSkill GracefulRoll Name

```
Graceful Roll
```

## Acrobatics SubSkill GracefulRoll Description

```
Twice as effective as a normal Roll
```

## Acrobatics SubSkill Dodge Name

```
Dodge
```

## Acrobatics SubSkill Dodge Description

```
Reduce attack damage by half
```

## Acrobatics SubSkill Dodge Stat

```
Dodge Chance
```

## Acrobatics Listener

```
Acrobatics:
```

## Acrobatics Roll Text

```
**Rolled**
```

## Acrobatics SkillName

```
ACROBATICS
```


##Acrobatics
## Guides Acrobatics Section 0

```
About Acrobatics:
Acrobatics is the art of moving Gracefuly in mcMMO.
It provides combat bonuses and environment damage bonuses.

XP GAIN:
To gain XP in this skill you need to perform a dodge
in combat or survive falls from heights that damage you.
```

## Guides Acrobatics Section 1

```
How does Rolling work?
You have a passive chance when you take fall damage
to negate the damage done. You can hold the sneak button to
double your chances during the fall.
This triggers a Graceful Roll instead of a standard one.
Graceful Rolls are like regular rolls but are twice as likely to
occur and provide more damage safety than regular rolls.
Rolling chance is tied to your skill level
```

## Guides Acrobatics Section 2

```
How does Dodge work?
Dodge is a passive chance when you are
injured in combat to halve the damage taken.
It is tied to your skill level.
```


https://mcmmo.org/wiki/Acrobatics
