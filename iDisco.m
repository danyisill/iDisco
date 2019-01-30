#include <time.h>
#import "iTunes.h"
#import "Cocoa/Cocoa.h"
#define DISCORD_DISABLE_IO_THREAD true
#include "discord_rpc.h"

#define APPID "393015284115439626"

#define dpush() Discord_UpdateConnection(); Discord_RunCallbacks();

BOOL ready_b, np;
iTunesApplication *iTunes;
iTunesTrack *cur;

void post(time_t timestamp, NSString *top, NSString *bottom){
	DiscordRichPresence discordPresence;
	memset(&discordPresence, 0, sizeof(discordPresence));
	discordPresence.state = [bottom UTF8String];
	discordPresence.details = [top UTF8String];
	discordPresence.startTimestamp = timestamp;
	discordPresence.largeImageKey = "itunes";
	Discord_UpdatePresence(&discordPresence);
	dpush();
}
void push_trackinfo(void){
	cur = [iTunes currentTrack];
	np = [iTunes playerState] == iTunesEPlSPlaying;
	post(np?(time_t) difftime(time(NULL), [iTunes playerPosition]):0,
		[NSString stringWithFormat:@"%@ - %@", [cur artist], [cur album]],
		[NSString stringWithFormat:@"%@%s", [cur name], np?"":" (Paused)"]);
}
void ready(const DiscordUser *connectedUser){
	ready_b = true;
	printf("connected to %s#%s - %s\n", connectedUser->username, connectedUser->discriminator, connectedUser->userId);
}
void errlog(int e, const char *m){
	printf("disconnected (%d: %s)\n", e, m);
}
void noop(){}
void trap(){
	puts("interrupt");
	Discord_Shutdown();
	exit(0);
}
int main(void){
	signal(SIGINT, trap);
	iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	[[NSOperationQueue mainQueue] addOperationWithBlock: ^(void){
		DiscordEventHandlers handlers;
		memset(&handlers, 0, sizeof(handlers));
		handlers.ready = ready;
		handlers.disconnected = errlog;
		handlers.errored = errlog;
		handlers.joinGame = noop;
		handlers.spectateGame = noop;
		handlers.joinRequest = noop;
		Discord_Initialize(APPID, &handlers, false, NULL);
		dpush();
	}];
	[[NSOperationQueue mainQueue] addOperationWithBlock: ^(void){
		sleep(3); //it better take less than 3s
		dpush();
		puts("init");
		if(ready_b && [iTunes isRunning])
			push_trackinfo();
	}];
	[[NSDistributedNotificationCenter defaultCenter]
		addObserverForName: @"com.apple.iTunes.playerInfo"
		object: nil
		queue: [NSOperationQueue mainQueue]
		usingBlock: ^(NSNotification *notification) {
			push_trackinfo();
		}];
	[[NSRunLoop mainRunLoop] run];
}