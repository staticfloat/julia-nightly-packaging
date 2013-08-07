#!/usr/bin/env julia
#
# Usage:
#   ./upload_binary.jl <path to binary file> <binary AWS key>
#
# Example:
#   ./upload_binary.jl /tmp/Julia-0.2-pre.dmg /bin/osx/x64/0.2/julia-0.2-unstable.dmg

if !haskey(ENV, "AWS_ID") || !haskey(ENV, "AWS_SECKEY")
    error( "You must set the environment variables AWS_ID and AWS_SECKEY to access your account on AWS" )
end

if length(ARGS) != 2
    error( "You must pass <file> and <upload key> to this script!" )
end

file = ARGS[1]
key = ARGS[2]

if !isfile(file)
    error( "Could not open $file" )
end

f = open(file, "r")


# Man, these take a long time to load. :(
using AWS
using AWS.S3

env = AWSEnv(ENV["AWS_ID"], ENV["AWS_SECKEY"], EP_US_EAST_NORTHERN_VIRGINIA)
acl = S3.S3_ACL()
acl.acl = "public-read"

S3.put_object(env, "julialang", key, f)
S3.put_object_acl(env, "julialang", key, acl )
close(f)
