<img width="1536" height="926" alt="Screenshot 2025-10-19 at 1 54 51 PM" src="https://github.com/user-attachments/assets/0642f045-f32a-4910-8662-7545b566a4d7" />

## Explanation

I am in FIRST Robotics Compitition and my team is kinda small and we dont have our own field to practice on, so I wanted to make a godot project which will render the robot and the field, so I can practice driving the robot and scoring through the simulation, even if i dont have access to a real field.

The way this works is when the simulation is run, pose values are published to data entries in the NetworkTables, and my godot program subscribes to the data it needs, reads the values, and updates the position and rotation of the model to render the data in 3D. (rotations was so annoying :sob:).

Currently, its not very extensible and requires a specific setup to run.
  
- It needs to have a wpilib simulation to connect to.
- It needs to have poses published to `/AdvantageKit/RealOutputs/FieldSimulation/RobotPose`, `/AdvantageKit/RealOutputs/AScope/componentPoses`, and `/AdvantageKit/RealOutputs/FieldSimulation/Coral`
- It also needs a valid robot model (advantagescope custom assets config formatted) in the user data directory:
- Windows: `%APPDATA%\Godot\app_userdata\3681-sim\robot/`
- macOS: `~/Library/Application Support/Godot/app_userdata/3681-sim/robot/`
- Linux: `~/.local/share/godot/app_userdata/3681-sim/robot/`

### Example:
<img width="920" height="172" alt="Screenshot 2025-10-20 at 2 31 37 PM" src="https://github.com/user-attachments/assets/a3b055d1-dfc0-4269-a2fa-e00237084535" />  

---

Because of this I've included a demo video to demonstrate

Godot does not have a msgpack or a networktables decoder (as far as i could find) so I had to write them myself, and that's where the bulk of the effort went. I also spent way too long getting rotations working before realizing i read the spec wrong. (i was reading euler angles when it was a quaternion 😑)

## Technologies ive used
- Godot
- WPILIB
- NetworkTables
