#!/usr/bin/env julia

if length(ARGS) < 2
    println( "Usage: ./report_nightly.jl \"target\" \"url\"" )
    exit( -1 )
end

using HTTPClient.HTTPC

target = ARGS[1]
version = ARGS[2]
url = ARGS[3]

json = "{\"target\": \"$target\", \"url\":\"$url\", \"version\":\"$version\"}"
ro = RequestOptions( content_type = "application/json" )

post("http://status.julialang.org/put/nightly", json ) 
