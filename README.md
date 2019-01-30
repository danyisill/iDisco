Why use it?
1. event based so it reacts instantly
2. written in objective c so it's pretty snappy

How to build?
1. build official [discord-rpc](https://github.com/discordapp/discord-rpc) with ENABLE_IO_THREAD=OFF
2. make

Or just download binary from releases

Bugs

1. discord connection isnt synchronized
2. need to correct timestamp if actual playback starts after notification was posted
3. keeps itunes open all the time