#import "iTunes.h"
#import "Cocoa/Cocoa.h"
#include "discord_rpc.h"
#define APPID "393015284115439626"
void trap(){
	puts("exit");
	Discord_Shutdown();
	exit(0);
}
DiscordRichPresence presence = {.largeImageKey = "itunes"};
DiscordEventHandlers handlers = {NULL, trap, trap};
int main(void){
	signal(SIGINT, trap);
	signal(SIGTERM, trap);
	Discord_Initialize(APPID, &handlers, false, NULL);
	sleep(3); //it better take less than 3s
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	void (^trackinfo)(NSNotification *) = ^(NSNotification *note){
		iTunesTrack *cur = [iTunes currentTrack];
		BOOL np = [iTunes playerState] == iTunesEPlSPlaying;
		presence.details = [[NSString stringWithFormat:@"%@ - %@", [cur artist], [cur album]] UTF8String];
		presence.state = [[NSString stringWithFormat:@"%@ %s", [cur name], np?"":"(Paused)"] UTF8String];
		presence.startTimestamp = (time_t) np * difftime(time(NULL), [iTunes playerPosition]);
		Discord_UpdatePresence(&presence);
	};
	trackinfo(NULL);
	[[NSDistributedNotificationCenter defaultCenter]
		addObserverForName: @"com.apple.iTunes.playerInfo"
		object: nil
		queue: [NSOperationQueue mainQueue]
		usingBlock: trackinfo];
	[[NSRunLoop mainRunLoop] run];
}