#!/usr/bin/env julia

if length(ARGS) < 1
    println( "Usage: ./report_nightly.jl \"target\" \"url\" \"log_url\"" )
    exit( -1 )
end

using HTTPClient.HTTPC

target = ARGS[1]
url = ARGS[2]
log_url = ARGS[3]

json = "{\"target\": \"$target\", \"url\":\"$url\", \"log_url\":\"$log_url\"}"
ro = RequestOptions( content_type = "application/json" )

post("http://status.julialang.org/put/nightly", json ) 
