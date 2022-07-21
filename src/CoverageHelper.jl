module CoverageHelper

using Pkg
using Coverage

"""
    test(pkgname[; work_dir=pwd(), rm_lcov=true, rm_cov=true, css=:gruvbox])

Run the test suite of `pkgname` (which must be checked out for
development) and generate a HTML coverage report using the `lcov`
program `genhtml`. Afterwards, clean up the coverage files from the
source directory. By default, a custom Gruvbox-based theme is used for
the coverage report, disable by passing `css=nothing` or,
alternatively, a custom CSS file: `css="path/to/theme.css"`.
"""
function test(pkgname; work_dir=pwd(), rm_lcov=true, rm_cov=true, css=:gruvbox)
    deps = Pkg.dependencies()
    pkg = nothing
    for (k,v) in Pkg.dependencies()
        if v.name == pkgname
            pkg = v
            break
        end
    end

    isnothing(pkg) &&
        error("Could not find package $(pkgname) among dependencies")
    isdir(pkg.source) ||
        error("$(pkgname) does not exist locally")

    Pkg.test(pkgname, coverage=true)

    coverage = process_folder(joinpath(pkg.source, "src"))

    out = joinpath(work_dir, "out")
    mkpath(out)

    lcov_file = joinpath(work_dir, "lcov.info")
    LCOV.writefile(lcov_file, coverage)
    args = [lcov_file, "--output-directory", out]

    if !isnothing(css)
        if css == :gruvbox
            css = joinpath(dirname(@__FILE__), "gruvbox.css")
        end

        append!(args, ["-c", css])
    end

    cmd = `genhtml $args`

    run(cmd)

    rm_lcov && rm(lcov_file)

    if rm_cov
        pat = r"\.jl\.([0-9]+)\.cov$"
        for dir in ["src", "test"]
            path = joinpath(pkg.source, dir)
            foreach(f -> rm(joinpath(path, f)),
                    filter(f -> !isnothing(match(pat, f)), readdir(path)))
        end
    end

    println("\nCoverage report saved in ", joinpath(out, "index.html"))
end

end
