SRC_DIR := "./src"

JULIA := "julia"

# Get an interactive shell with the module in scope
interactive:
    {{ JULIA }} --project -ie "using PandemicAIs"

# Format all files in `target`
format target=SRC_DIR:
    {{ JULIA }} -E 'using JuliaFormatter; format("{{ target }}")'

# Get an interactive notebook
notebook:
    {{ JULIA }} -e 'using Pluto; Pluto.run()'
