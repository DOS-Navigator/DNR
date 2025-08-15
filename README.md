# DNR
DOS Navigator Revived

## Project Status (August 2025)

This project is an effort to modernize the original DOS Navigator codebase to compile with modern, open-source tools, specifically FreePascal and NASM.

### Progress
*   **Assembly Code:** The initial critical assembly files (`_MHZ.ASM`, `VGA33.ASM`, `SYSINT.ASM`) have been successfully converted from TASM to NASM syntax.
*   **Pascal Analysis:** A bottom-up analysis of the Pascal units has begun, starting with the dependency-free `OBJTYPE.PAS` unit.

### Current Blocker
The project is currently blocked due to fundamental issues with the development environment's toolchain. The FreePascal compiler (`fpc`) provided in the environment is unable to compile code for the target DOS platform, and numerous workarounds have failed. Furthermore, the environment exhibits inconsistent file system behavior, preventing reliable compilation even for a modern Linux target.

For a detailed log of the investigation and the specific errors encountered, please see `PROGRESS_LOG.md`.
