TOWER ICONS FOR THE STRATEGY INFO WINDOW
============================================================

Put one PNG per tower in this folder. The Strategy Info window shows it on one of the
five squares under REQUIRED TOWERS (hover a square to see the tower's name).

FORMAT
  - PNG, named exactly as in the lists below (spaces and capitals included).
  - Square images. The squares are about 76 x 76 pixels, so 128 x 128 or 256 x 256 is plenty.
    Non-square images are squeezed to fit, so crop them to a square first.
  - Transparent PNGs work best: the square's background is filled with the tower's rarity colour
    (Starter DCDCDC, Intermediate 00FF00, Advanced 42C6FF, Hardcore C38CE8, Evolved 42C6FF,
    Golden Perk FFF200, Exclusive FF4B6E), set in TowerColorHex() in lib\TowerDatabase.ahk.
  - A tower without a file is not an error: its square shows the tower's initials.
  - Reopen the Info window after adding files (no restart needed).

SPELLING
  Strat files may use short names; the macro maps them to the names below:
  DJ = DJ Booth, Crook = Crook Boss, Gatling = Gatling Gun, Mecha = Mecha Base,
  G Minigunner = Golden Minigunner (same for the other "G ..." golden perks).
  Capitals, spaces and punctuation do not matter in the strat file ("dj", "hacker" are fine).

STARTER  (7 files)
  Scout.png
  Sniper.png
  Paintballer.png
  Demoman.png
  Boomerang.png
  Slime Trooper.png
  Soldier.png

INTERMEDIATE  (15 files)
  Freezer.png
  Assassin.png
  Militant.png
  Shotgunner.png
  Hunter.png
  Pyromancer.png
  Ace Pilot.png
  Medic.png
  Farm.png
  Electroshocker.png
  Rocketeer.png
  Trapper.png
  Pulse Trooper.png
  Military Base.png
  Crook Boss.png

ADVANCED  (13 files)
  Commander.png
  Warden.png
  Cowboy.png
  DJ Booth.png
  Tesla.png
  Saboteur.png
  Minigunner.png
  Ranger.png
  Pursuit.png
  Gatling Gun.png
  Turret.png
  Mortar.png
  Mercenary Base.png

HARDCORE  (5 files)
  Brawler.png
  Necromancer.png
  Accelerator.png
  Engineer.png
  Hacker.png

EVOLVED  (5 files)
  Operator.png
  Enforcer.png
  Kingpin.png
  Juggernaut.png
  Mecha Base.png

GOLDEN PERK  (8 files)
  Golden Minigunner.png
  Golden Pyromancer.png
  Golden Crook Boss.png
  Golden Scout.png
  Golden Cowboy.png
  Golden Soldier.png
  Golden Demoman.png
  Golden Snowballer.png

EXCLUSIVE  (21 files)
  Gladiator.png
  Commando.png
  Slasher.png
  Frost Blaster.png
  Archer.png
  Swarmer.png
  Toxic Gunner.png
  Sledger.png
  Executioner.png
  Elf Camp.png
  Jester.png
  Cryomancer.png
  Hallow Punk.png
  Harvester.png
  Snowballer.png
  Elementalist.png
  Firework Technician.png
  Biologist.png
  Warlock.png
  Spotlight Tech.png
  War Machine.png

TOTAL: 74 files

TO ADD A TOWER
  Add a "Name|Category" line to lib\TowerDatabase.ahk and put <Name>.png here.
