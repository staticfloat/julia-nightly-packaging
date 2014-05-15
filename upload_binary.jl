#!/usr/bin/env julia
#
# Usage:
#   ./upload_binary.jl <path to binary file> <binary AWS key>
#
# Example:
#   ./upload_binary.jl /tmp/Julia-0.2-pre.dmg /bin/osx/x64/0.2/julia-0.2-prerelease-1a2b3c4d.dmg

if length(ARGS) < 2
    error( "Usage: ./upload_binary.jl <file> <upload_path>")
end

file = ARGS[1]
key = ARGS[2]

if !isfile(file)
    error( "Could not open binary $file" )
end

f = open(file, "r")

# Man, these take a long time to load. :(
using AWS
using AWS.S3

env = AWSEnv()
acl = S3.S3_ACL()
acl.acl = "public-read"

# Upload the actual file (if it's a .log file, set the content_type to "text/plain")
if file[end-3:end] == ".log"
    S3.put_object(env, "julianightlies", key, f, content_type="text/plain")
else
    S3.put_object(env, "julianightlies", key, f)
end
S3.put_object_acl(env, "julianightlies", key, acl )
close(f)

println("$key uploaded successfully")
