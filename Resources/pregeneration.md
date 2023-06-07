# Pre-generation of Worlds on Minecraft

## Efficient Minecraft World Management

Welcome to this page, where we provide suggestions for managing your Minecraft worlds through chunk pre-generation (pregen). Our aim is to help improve server performance and enhance the gaming experience for your players.

Please keep in mind that every server type is unique, and what works for me may not necessarily work for you. The primary goal here is to explore your options, gain knowledge from the suggestions, and apply them according to your specific situation.

## An Introduction to Chunk Pre-Generation

Chunk pre-generation involves generating specific chunks within your world map's region files in advance, alleviating the computational load at the moment and avoiding the need for calculations later.

Typically, when a player joins the server and begins exploring, they may encounter chunks that have never been visited before. In such cases, the server needs to generate and load those chunks based on the world seed, presenting them to the player for interaction.

By pre-generating these chunks ahead of time, we can bypass this step, reducing stress on the server and eliminating the "wait time" for the player. Although the savings in server stress and wait time may seem small individually, in a multiplayer environment with multiple active players, constant movement, teleportation, world switching, and more, these factors accumulate. This cumulative impact can potentially lead to a drop in TPS (Ticks Per Second) on your server. 

Pre-generating the world can help alleviate this strain, providing a smoother experience for players.

### Questions I always get

Q: Can I pregen on 1.8 or only on 1.20 worlds?
A: There are plugins for almost every version.

Q: But pregen drops the tps of the server!!
A: Sometimes, this depends on your hosting solution and server-engine. This is server-management, don't run it live if it impacts your server too much. Chunky has proven to run well on Paper.

Q: Do I need to have a big server to pregen?
A: Not really, but yes, I do recommend having 4GB or more available, and you can offsite pregenerate most of the time (local system for example)

Q: It keeps crashing my server!
A: See previous Q/A, and to be honest, this isn't a support page. Talk to the authors of the plugins.

Q: Can I pregen all my worlds/servers?
A: Yes, I would do them all.

Q: My world uses a special world generator, now what?
A: Pregen it, that world generator should kick in and generate the chunks as expected.

Q: Do I still need the custom world generator plugin when everything's generated?
A: Yes, and no. No, because it's all generated, yes, because some world gen plugins offer special features. Use common sense in this case.

Q: Do I need a worldborder?
A: Yes and no. Yes, because it's making pregen a lot easier (gives you control), and once done, you don't want players to into un-genned areas. But no, you can temporarily use a worldborder, and when the pregenning is done you can remove the worldborder. I know some people just want to pregen the first 50k radius of their world. 

Q: How much storage will this take up to pregen a whole world?
A: This depends on how much you do. 50,000 blocks by 50,000 blocks (25k square radius) can be between 25 to 50gb. So make sure your host can support this.

Q: Which plugin do you recommend?
A: I will get into that further down this document, but the short answer is Chunky, unless you're on 1.12.2 or older, then it will be WorldBorder.

Q: Any tricks to speed things up?
A: Yes, see further down this document, but the short answer is: cluster your tasks.

Q: Do I still need to --forceUpgrade and everything?
A: Well, I am sure people will say no, but my personal experience is that I have the _least_ amount of issues when I --forceUpgrade between bigger version updates, before running Chunky. After the release of 1.19.x this isn't really needed anymore in my opinion. 

Q: Okay, I have a 5k world pregenned, now 1.21 comes out, NOW WHAT
A: Well, that's something you have to think about BEFORE doing any pregen, rather than realise after the fact. See further down this document 'World expansions'. You will have to think it through properly how you want to run your server.

Q: What if I already have started pregen and want to stop it?
A: I believe both WorldBorder and Chunky support pause and/or stop/cancel task. 

Q: What if I already have a pregen world and need to do it again?
A: If you started with say 500x500 and want to make it 1000x1000, you can start pregen again. The plugins will check if the chunk has already been generated and finish really quickly on it. If it took an hour first, then that same amount of chunks will now take a few minutes maybe fifteen. But not another hour (just an example).

Q: After an upgrade, convert, pregen I get weird (world) errors in the console?
A: You can ask for server and plugin support on SpigotMC.org in the appropriate forum. 

## Minecraft version Upgrades

Personally I don't run --forceUpgrade going from 1.19.3 to 1.19.4, unless there's a world-generation tweak/bugfix or something world generation related.

Personally I do run --forceUPgrade going from for example 1.12 to 1.13, or 1.13 to 1.15, or 1.17 to 1.19

I recommend to run --forceUpgrade before running a world pre-generation. This way existing chunks are converted by Mojang's server engine to the version you're upgrading to. Before generating new chunks for it, which will then be made for that version. It feels like this would be common sense. You can also run --eraseCache alongside --forceUpgrade, to rebuild the light system, which can really help performance in some situations as well. 

See the topic below this one as to how I recommend dealing with upgrading/expanding existing worlds.

## World Expansion

New world? Easy: Pick a size, make it square, pre-generate it. When done: let your users enjoy it.

Upgrading in the future? Easy: Think about this before starting a new world. This way you can decide you will never expand again, or maybe reset when there's a big new version out. Or maybe you start small and expand over time. You can run --forceUpgrade and then expand the border a bit and pregen what's new.

Expanding existing world? Possible. When you've thought about it and started with a small world border and pregen that world. You can now run change the worldborder size and then pregen what's new.

Expanding existing world with a version upgrade? Possible. When you've thought about it and started with a small world border and pregen that world. You can now run --forceUpgrade and then expand the border a bit and pregen what's new. 

Personally I never delete worlds. So pregenning a world can start small. Small can be 500x500 but also 5000x5000. It all depends on what you can host, what you want to do, how many players you expect to get and what your long term plans are. For example, I have a ten year old world that started with very old beta stuff and over time we've expanded it with each version upgrade of Minecraft, so yes, around spawn the chunks are from old world generation but near the world border everything's fresh and new. Players in my experience have no issue with this. 

## Additional benefits

As previously mentioned, the performance on the server improves, places where pregen can benefit your server:

- Do the work now, to avoid having to do it later.
- Players moving around, and having a better experience.
- Overall server performance increase, creating room for fast players.
- Elytra is a feature in newer versions, chunks will show faster to the player.
- Trident in the rain with Riptide while wearing Elytra can create super speeds. In some situations having a pregen world can actually prevent a server from crawling to a halt. 
- No need in some situations to run a special custom world generator, the chunks are already there, you can technically remove the world generator plugins and save on cpu/ram.
- No weird old vs new chunk generation due to visited/unvisited chunks (consistency).
- Variety of world maps for websites look complete, instead of looking weird of having huge chunks of unvisited areas (dynmap, etc).
- Random teleporting features (BetterRTP, /cmi rt, etc) will have an easier time async loading and preloading chunks. This can help keep the tps up and give the player a smooth teleporting experience. 

## Trimming chunks

Pre-generating a chunk is generally referred to as filling, while removing chunks is called trimming. It's important to consider trimming chunks (accidentally) generated outside of the world border. This way they're all newly generated for the version of Minecraft you're generating new chunks when you expand the world border. 

So don't forget to trim outside of the old world border first, before expanding the world border and running another fill pregen.

## Tricks and Tips

Uber tip: Backup your whole server, including MYSQL databases etc, before even making any changes to your servers, be it an plugin update, --forceUpgrade run, a world pregen, or just tweaking configuration settings. Learn how to make backups, how to confirm they are working backups, how to roll back, etc. 

Biggest tip: Run --forceUpgrade when you go between major version updates of Minecraft. And even if you don't do that: pre-generate your worlds. All of them, on all your servers. There's no realistic downside to it.

Pretty Big tip: You can run it offsite. Your current host giving you issues? You can of course change to something else, but you can rent a cloud solution for the time you need it to keep the cost down a lot. And run a clone of your server there for --forceUpgrade and pre-generation. While you work on your live-server updates. This allows you to get a very expensive high quality host cheap for a short time, and you can convert multiple servers and worlds and lower your overall downtime. 

Big tip: You can cluster, you can run 5 instances of your server for example, pregen your spawn world first (your first world) so you don't risk losing or corrupting data. Put that on all the servers. Then put all the small worlds on the first one, and some bigger worlds one by one on the others. And just run the instances at basically the same time. The --forceUpgrade and pre-gen doesn't take much cpu/ram and you can easily run multiple instances at the same time (each on their own port) and you basically never have to login to the game anyway. But what finishes successfully you can move to the live server and test there. What hasn't completed doesn't add a queue and you can just run another instance at the same time for another world. 

Tip: When you run different instances on different ports to help you convert your worlds quickly, and pre-gen them quickly etc. You can remove any plugin that it really doesn't need, such as discord plugins, voting plugins, etc. Do keep multiverse-core and world generators that you need of course. Maybe keep world protection plugins as well.

Generic tip: You can even keep your live server running, but limit your players to your spawn and general world. While taking other things like a mini game world etc offline. You can prevent them from using that world. This way you have less downtime. And when a converted/pregenned world has finished you can just swap it live basically. And then test it, and if things seem fine you can grant players access to it again. 

Note: If you want to run pregen while the server is live: yes, this is possible. But it can and probably does slow it down. You and your players will have a longer 'meh' experience versus doing some smarty-pants server management as mentioned in the tips above. 

And final tip:

Keep the console to the server open, so you can see what goes wrong. If something goes wrong you can just start over that one world (after applying fixes) versus having to redo everything. Read the console, know what is going on. etc.

## Force Upgrade side-note

Eventually I might write a Github page like this one about server upgrades, but I will make a side note here regarding upgrading worlds from one version of Minecraft to another. 

Mojang has offered a way to forcefully run optimize and upgrade on your worlds. You can do this in singleplayer techcnically by pressing a button or just loading the world I think. But for a server you need to update your jvm startup parameters with either Force Upgrade option, and/or the Erase Cache option.

`--forceUpgrade` - One time converts world chunks to new engine version
`--eraseCache` - Removes caches. Cached data is used to store the skylight, blocklight and biomes, alongside other stuff

It's important to realise that you only need to run this once, subsequent server startups do not need this. This is recommended (in my opinion) to do between major versions or at least when there's world generation changes between versions.

`java` starts the jvm, `-jar` tells the jvm which jar file to start, like spigot.jar or paper.jar, and behind that, you can add `--forceUpgrade`. Do not add it before -jar, it has to be go behind it, because java startup flags go behind java and before -jar, and the Minecraft server startup params go behind the -jar

i.e.
`java -jar spigot.jar --forceUpgrade --eraseCache`

## Plugins and Tools/Resources

Get hosting that gives you console access, personally I avoid any control panel. I want full server access and a command line. Allowing me to use basic kernel commands to manage the data on the hosting solution is important. Having control over your data means you can back up properly, you can start servers properly, you can customize your servers properly, and you can run multiple instances properly and pre-gen in a comfortable way. Free hosting solutions that give you 5gb storage and no console access besides read-only: worthless in my opinion to properly run a server.

Use Chunky, and if you can't use Chunky, use WorldBorder plugin. I've tried other plugins but I had so/so experiences with them and reverted back to WorldBorder. I don't suggest running a server for a Minecraft version that isn't able to run Chunky. Stay current, keep your plugins current. 

**WorldBorder:**
- github (source code): https://github.com/Brettflan/WorldBorder
- download (1.15 and 1.16 fork): https://www.spigotmc.org/resources/worldborder-1-15.80466/
- download (1.13 and 1.14): https://www.spigotmc.org/resources/worldborder.60905/
- download (1.8.8 and 1.12.2): https://dev.bukkit.org/projects/worldborder

**Chunky:**
- github (source code): https://github.com/pop4959/Chunky
- download (1.13, to 1.20): https://www.spigotmc.org/resources/chunky.81534/

`Chunky commands I use PER world and from console:`
```
chunky world <world> - Set the world target
chunky worldborder - Use the world border center & radius
chunky shape <shape> - Set the shape to generate (I use square)
chunky quiet <interval> - Set the quiet interval (I use 120)
chunky start - Start a new chunk generation task
```

### Github document version

This is the second draft, updated June 7th, 2023, version 1.1.0 build 003, by Floris Fiedeldij Dop - https://www.1moreblock.com/