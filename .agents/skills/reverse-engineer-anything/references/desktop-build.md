# Desktop application environment builds

When the user asks to build an agent environment (AgentEnv bundle) for a Linux
desktop application with a concrete task (for example, changing a headline in
Inkscape or editing a spreadsheet in LibreOffice), use the build-computer
workflow:

1. Start an isolated build computer with `start_build_computer`.
2. Launch and drive the target Linux desktop application inside the build
   computer to establish the initial state and verify the task boundaries.
3. Export the desktop environment bundle and witness the task completion using
   the advertised desktop environment tools.
4. Preserve all returned Evidence IDs, artifact digests, and environment
   limitations. Close or release the build computer when the export and witness
   steps finish.
