WSTracker

WSTracker is a lightweight, accurate Ashita v4 addon designed to track Weapon Skill points for WS Unlocks, Breakable Weapon Unlocks, and the Dark Knight Job Unlock quest.

Unlike other trackers that rely on simple text scanning or guesswork, WSTracker uses recursive packet parsing to read the server's incoming action packets. This ensures 100% accuracy in detecting Skillchain bonuses (Level 1, 2, and 3) even in complex combat situations involving multiple targets or buffs.
Key Features

    Smart Weapon Detection: Automatically detects your equipped weapon and switches modes instantly:

        Latent Weapons (300 pts): Automatically sets target to 300 and enables Skillchain bonuses.

        Broken Weapons (500 pts): Automatically sets target to 500 for WS unlock quests.

        Chaosbringer (100 kills): Automatically enters "DRK Quest Mode" (Target 100, no SC bonuses).

    Accurate Skillchain Math: Correctly calculates points based on the trial rules:

        Base WS: +1 point

        Level 1 SC: +1 bonus (Total 2)

        Level 2 SC: +2 bonus (Total 3)

        Level 3 SC: +4 bonus (Total 5)

    Visual Progress Bar: A movable, minimal on-screen interface showing your exact progress.

    Completion Alerts: Notifies you in chat and visually when a trial is complete.

Supported Weapons

WSTracker currently contains an internal database for the following:

    Job Unlock: Chaosbringer (Dark Knight)

    WS Unlock (300 Pts): Sword of Trials, Club of Trials, Pole of Trials, Scythe of Trials, etc.

    Enhanced Crit Weapons (500 Pts): Destroyers, Hofud, Valkkyrie's Fork, Sandung, etc.

Note: If you equip a weapon not in the database, the addon defaults to "Standard Mode" (300 pts) but allows you to manually set the target.

Installation

    Download wstracker.lua.

    Place the file in your Ashita addons folder:
    Ashita/addons/wstracker/wstracker.lua

    Load the addon in game:

    /addon load wstracker


Commands

Command,Description

/wspt reset,Resets the current point counter to 0.

/wspt set <number>,"Manually sets the current points (e.g., /wspt set 150)."

/wspt target <number>,"Manually changes the target goal (e.g., /wspt target 500)."

/wspt drk,"Manually toggles ""DRK Mode"" (disables Skillchain bonuses)."

WSTracker listens for incoming 0x28 (Action) packets. Instead of scanning the entire packet blindly, it uses a recursive bit-unpacker to navigate the packet structure. It specifically locates the AdditionalEffect field where Skillchain messages are stored.

This method eliminates "false positives" (where damage numbers are mistaken for Skillchain IDs) and ensures that bonuses are applied only once per action.
