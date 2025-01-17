use clap::Parser;
use eggcc::util::{visualize, Run, RunType, TestProgram};
use std::path::PathBuf;

#[derive(Debug, Parser)]
struct Args {
    /// A directory for debug output, including
    /// svgs for the rvsdg, cfgs, ect.
    #[clap(long)]
    debug_dir: Option<PathBuf>,
    /// Configure the output of the tool, which can be an optimized bril program,
    /// an optimized CFG, or more.
    /// See documentation for [`RunType`] for different options.
    #[clap(long, default_value_t = RunType::RvsdgOptimize)]
    run_mode: RunType,
    /// Evaluate the resulting program and output
    /// the result.
    #[clap(long)]
    interp: bool,

    #[clap(long)]
    profile_out: Option<PathBuf>,

    /// The bril program to optimize
    file: PathBuf,
    /// The arguments to the bril program
    /// (only used when interpreting)
    bril_args: Vec<String>,
}

fn main() {
    let args = Args::parse();

    if let Some(debug_dir) = args.debug_dir {
        if let Result::Err(error) = visualize(TestProgram::File(args.file.clone()), debug_dir) {
            eprintln!("{}", error);
            return;
        }
    }

    if args.interp && !args.run_mode.produces_bril() {
        eprintln!(
            "Cannot interpret run type {} because it doesn't produce a bril program.",
            args.run_mode
        );
        return;
    }

    let run = Run {
        prog_with_args: TestProgram::File(args.file.clone()).read_program(),
        test_type: args.run_mode,
        interp: args.interp,
        profile_out: args.profile_out,
    };

    let result = run.run();

    if args.interp {
        println!("{}", result.result_interpreted.unwrap());
    } else {
        for visualization in result.visualizations {
            println!("visualization of {}:", visualization.name);
            println!("{}", visualization.result);
            println!();
        }
    }
}
