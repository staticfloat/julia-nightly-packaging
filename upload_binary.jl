#!/usr/bin/env julia
#
# Usage:
#   ./upload_binary.jl <path to binary file> <binary AWS key>
#
# Example:
#   ./upload_binary.jl /tmp/Julia-0.2-pre.dmg /bin/osx/x64/0.2/julia-0.2-unstable.dmg

if length(ARGS) < 2
    error( "Usage: ./upload_binary.jl <file> <upload_path>")
end

file = ARGS[1]
key = ARGS[2]

if !isfile(file)
    error( "Could not open binary $file" )
end

if !isfile(logfile)
	error( "Could not open logfile $logfile")
end

f = open(file, "r")

# Man, these take a long time to load. :(
using AWS
using AWS.S3

env = AWSEnv()
acl = S3.S3_ACL()
acl.acl = "public-read"

S3.put_object(env, "julialang", key, f)
S3.put_object_acl(env, "julialang", key, acl )
close(f)

println("$key uploaded successfully")
