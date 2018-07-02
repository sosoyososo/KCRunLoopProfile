#import "KCRunLoopProfile.h"

#import "KSCrashMonitor.h"
#import "KSMachineContext.h"
#import "KSCrashMonitorContext.h"
#import "KSStackCursor.h"
#import "KSID.h"
#import "KSCrash.h"
#import "KSCrashInstallationConsole.h"
#import "KSCrashReportFilterAppleFmt.h"

#define Profile_Time_Throttle 1.0/120

static char g_eventID[37];
static KSCrash_MonitorContext g_monitorContext;
static KSStackCursor g_stackCursor;
static NSTimeInterval _s_timerDuration;
static void(^_g_callBack)(NSArray<NSString *>*);


@interface KCRunLoopProfile()
@property NSTimer *timer;
@property dispatch_queue_t queue;
@property BOOL inProfile;
@end


@implementation KCRunLoopProfile {
    CFRunLoopObserverRef observer;
}
static KCRunLoopProfile * _s_Profile = nil;
+ (void)setStackTraceCallBackWhenSlow:(void(^)(NSArray<NSString *>*))stackTraceCallBack {
    _g_callBack = stackTraceCallBack;
}

+ (void)profile {
    [self profileWithCheckDuration:Profile_Time_Throttle];
}
+ (void)profileWithCheckDuration:(NSTimeInterval)duration {
    _s_timerDuration = duration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _s_Profile = [[KCRunLoopProfile alloc] init];
        
        [KSCrash sharedInstance].sink = [KSCrashReportFilterAppleFmt filterWithReportStyle:KSAppleReportStyleSymbolicated];
        [[KSCrash sharedInstance] install];
        ksid_generate(g_eventID);
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:_s_Profile
                                             selector:@selector(startProfile)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:_s_Profile
                                             selector:@selector(endProfile)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:_s_Profile
                                             selector:@selector(endProfile)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:_s_Profile
                                             selector:@selector(endProfile)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
}

static NSDate *date = NULL;
static void runLoopObserverCallBack(CFRunLoopObserverRef observer,  CFRunLoopActivity activity, void *info) {
    if (activity == kCFRunLoopBeforeSources) {
        if (date == NULL) {
            date = [NSDate date];
        }
    } else if (activity == kCFRunLoopBeforeWaiting) {
        date = NULL;
    }
}

- (void)startProfile {
    if (self.inProfile) {
        return;
    }
    
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
        observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                           kCFRunLoopAllActivities,
                                           YES,
                                           0,
                                           &runLoopObserverCallBack,
                                           &context);
        
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
        [self addMainRunloopWatcher];
    });
}

- (void)endProfile {
    if (!self.inProfile) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (observer != NULL) {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
            observer = NULL;
        }
        if (self.timer != NULL) {
            [self.timer invalidate];
            self.timer = NULL;
        }
    });
}

- (void)addMainRunloopWatcher {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _queue = dispatch_queue_create("_runloop_profile_queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_queue, (__bridge void *)self, (__bridge void *)_queue, NULL);
    });
    dispatch_async(_queue, ^{
        self.timer = [NSTimer timerWithTimeInterval:_s_timerDuration*0.85 repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self checkTimer];
        }];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
        while (kCFRunLoopRunStopped != CFRunLoopRunInMode(kCFRunLoopDefaultMode, ((NSDate *)[NSDate distantFuture]).timeIntervalSinceReferenceDate, NO)) {
        }
    });
}


- (void)checkTimer {
    if (date != NULL) {
        NSTimeInterval checkRet = [[NSDate date] timeIntervalSince1970] - [date timeIntervalSince1970];
        if (checkRet > _s_timerDuration) {
            [self performMainThreadSlowAction];
        }
    }
}

- (void)performMainThreadSlowAction {
    ksmc_suspendEnvironment();
    
    KSCrash_MonitorContext* crashContext = &g_monitorContext;
    memset(crashContext, 0, sizeof(*crashContext));
    
    KSMC_NEW_CONTEXT(machineContext);
    ksmc_getContextForThread(ksthread_self(), machineContext, true);
    
    const char* name = "RunLoop Profile";
    crashContext->crashType = KSCrashMonitorTypeCPPException;
    crashContext->eventID = g_eventID;
    crashContext->registersAreValid = false;
    crashContext->stackCursor = &g_stackCursor;
    crashContext->CPPException.name = name;
    crashContext->exceptionName = name;
    crashContext->crashReason = "发生了某些事情导致主线程变慢";
    crashContext->offendingMachineContext = machineContext;
    
    kscm_handleException(crashContext);
    
    ksmc_resumeEnvironment();
    
    [[KSCrash sharedInstance] sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if (filteredReports.count > 0) {
            _g_callBack([filteredReports[0] componentsSeparatedByString:@"\n"]);
        }
    }];
}


@end
