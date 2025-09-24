# csvmd

A CLI tool built in Zig for converting CSV files to Markdown tables.

## Features

- Convert CSV files to properly formatted Markdown tables
- Support for quoted fields with commas
- Command-line interface with help and version options
- Output to stdout or save to file
- Handles various CSV formats and edge cases

## Installation

### Prerequisites
- Zig compiler (version 0.11.0 or later)

### Building from source
```bash
git clone https://github.com/timrogersmax/csvmd.git
cd csvmd
zig build
```

The compiled binary will be available in `zig-out/bin/csvmd`.

## Usage

```bash
csvmd [options] <input.csv> [output.md]
```

### Options
- `-h, --help` - Show help message
- `-v, --version` - Show version information

### Arguments
- `input.csv` - Input CSV file (required)
- `output.md` - Output Markdown file (optional, defaults to stdout)

### Examples

Convert CSV to Markdown and display in terminal:
```bash
./zig-out/bin/csvmd examples/people.csv
```

Convert CSV to Markdown and save to file:
```bash
./zig-out/bin/csvmd examples/people.csv output.md
```

Display help:
```bash
./zig-out/bin/csvmd --help
```

## Sample Input and Output

### Input CSV (people.csv):
```csv
Name,Age,City,Occupation
John Doe,28,New York,Software Engineer
Jane Smith,32,San Francisco,Product Manager
Bob Johnson,45,Chicago,Data Scientist
Alice Brown,29,Austin,UX Designer
```

### Output Markdown:
```markdown
| Name | Age | City | Occupation |
| --- | --- | --- | --- |
| John Doe | 28 | New York | Software Engineer |
| Jane Smith | 32 | San Francisco | Product Manager |
| Bob Johnson | 45 | Chicago | Data Scientist |
| Alice Brown | 29 | Austin | UX Designer |
```

## CSV Format Support

- Standard comma-separated values
- Quoted fields (handles commas within quotes)
- Empty fields
- Various line endings (LF, CRLF)

## Development

### Building
```bash
zig build
```

### Running tests
```bash
zig build test
```

### Running in development
```bash
zig build run -- examples/people.csv
```

## License

MIT License