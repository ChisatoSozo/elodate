use chrono::Local;
use env_logger::{Builder, Env};
use log::{LevelFilter, SetLoggerError};
use std::fs::{File, OpenOptions};
use std::io::{self, Write};
use std::sync::Mutex;

struct RotatingFileLogger {
    file: Mutex<Option<File>>,
    last_date: Mutex<String>,
}

impl RotatingFileLogger {
    fn new() -> Self {
        RotatingFileLogger {
            file: Mutex::new(None),
            last_date: Mutex::new(String::new()),
        }
    }

    fn get_or_create_file(&self) -> std::io::Result<File> {
        let current_date = Local::now().format("%Y-%m-%d").to_string();
        let mut last_date = self.last_date.lock().unwrap();
        let mut file = self.file.lock().unwrap();

        if *last_date != current_date {
            let log_file_name = format!("{}.log", current_date);
            *file = Some(
                OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open(log_file_name)?,
            );
            *last_date = current_date;
        }

        Ok(file.as_ref().unwrap().try_clone()?)
    }
}

impl Write for RotatingFileLogger {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        let mut file = self.get_or_create_file()?;
        file.write(buf)
    }

    fn flush(&mut self) -> std::io::Result<()> {
        let mut file = self.get_or_create_file()?;
        file.flush()
    }
}

struct MultiplexedLogger {
    console: io::Stdout,
    file: RotatingFileLogger,
}

impl MultiplexedLogger {
    fn new() -> Self {
        MultiplexedLogger {
            console: io::stdout(),
            file: RotatingFileLogger::new(),
        }
    }
}

impl Write for MultiplexedLogger {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        let console_result = self.console.write(buf);
        let file_result = self.file.write(buf);

        // If both writes succeed, return the number of bytes written.
        // If either fails, return the error.
        match (console_result, file_result) {
            (Ok(_), Ok(bytes)) => Ok(bytes),
            (Err(e), _) | (_, Err(e)) => Err(e),
        }
    }

    fn flush(&mut self) -> io::Result<()> {
        self.console.flush()?;
        self.file.flush()?;
        Ok(())
    }
}

pub fn init_logs() -> Result<(), SetLoggerError> {
    let multiplexed_logger = Box::new(MultiplexedLogger::new());

    let mut builder = Builder::from_env(Env::default().default_filter_or("info"));

    builder
        .format(|buf, record| {
            writeln!(
                buf,
                "{} [{}] - {} ({})",
                Local::now().format("%Y-%m-%d %H:%M:%S"),
                record.level(),
                record.args(),
                record.module_path().unwrap_or("unknown")
            )
        })
        .target(env_logger::Target::Pipe(multiplexed_logger));

    builder.try_init()?;

    // Set the maximum log level
    log::set_max_level(LevelFilter::Info);

    Ok(())
}
