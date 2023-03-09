use std::env;
use std::process::Command;

fn main() {
    let dd_command: Vec<String> = env::args().collect();
    let mut command = Command::new(&dd_command[1]);

    // dogstatsd requires a start argument to run
    let dd_arg = command.get_program().to_str().unwrap();
    if dd_arg.ends_with("dogstatsd") {
        command.arg(&dd_command[2]);
    }

    spawn(command);
}
fn spawn(mut command: Command) {
    if let Ok(mut dd_process) = command.spawn() {
        let status = dd_process.wait().expect("dd_process wasn't running");
        println!("DataDog process {} has finished", status);
        if !status.success() {
            spawn(command);
        }
    } else {
        println!("Datadog process did not start successfully");
    }
}