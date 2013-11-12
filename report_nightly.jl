#!/usr/bin/env julia

if length(ARGS) < 1
    println( "Usage: ./report_nightly.jl \"target\" \"url\"" )
    exit( -1 )
end

using HTTPClient.HTTPC

target = ARGS[1]
url = ARGS[2]

json = "{\"target\": \"$target\", \"url\":\"$url\"}"
ro = RequestOptions( content_type = "application/json" )

post("http://status.julialang.org/put/nightly", json ) 
