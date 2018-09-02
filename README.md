# PartyLock

Wow Addon for Mythic Party locks

/partylock -- opens addon

/partylock center -- recenters addon if removed from the page

/partylock request -- same as pressing the button. Requests update from all guild and party members

/pl -- shortcut to open addon

Special Thanks To:
- Cromzinc for all the suggestions on the UI and functionality
- Beerhunter and Chairepoppa for testing where few would
- Gistbek for suggesting adding top mythic+ level, <Esc> key for closing addon, and (hopefully adding mini-map icon)
- To the guild Wasted Knights for putting up with my error prone programming

- v1.05
    - Refactored for better clarity.
    - Removed global variables and called local functions to remove global dependencies.
    - Added "online" column to filter on vs offline guild members.
    - Fixed issue where guild members would normally look offline although they were online
    - Helped reduce spam to WoW API to prevent player from being dc'd due to such spam
    - Request button updates guild AND party, instead of just guild
- v1.04
    - Quick update for BFA. Thanks Morl0ck for updating when I could not!
- v1.03
    - Stopped sending messages to guild if the player does not belong to one
    - Should only show players capable of doing mythics. This should filter out lower level players from being added
    - Significant UI upgrade. Now in better table format. Player may sort by column
    - Able to close the AddOn with the <Esc> Key
    - Added request button to update all guild and party members. A lockout of only once every 2 minutes is in place.
- v1.02
    - Cleaned up overall code
    - Improved chances of getting player specialization correct when first loading
    - Set correct party/guild tab when opening
    - Improved sending to guild more often than once every login
    - Listed characters now in alphabetical order by character name
    - Should show all guild members even if they are offline
    - Slightly improved UI lookup
    - Improved mythic time comparison. Should also work with any version older versions
    - Grayed out characer names are considered offline
    - Request button for guild members to update each other.
    - New Command: /partylock center to recenter if off screen
-v1.01
    - Quick hotfix for parsing issue with spec
- v1.0
    - Initial release. Capable of showing party and guild members name, spec, ilevel, and saved intsances
