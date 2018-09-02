//
//  ADBCopyFile.m
//  Boxer
//
//  Created by C.W. Betts on 9/2/18.
//  Copyright © 2018 Alun Bestor and contributors. All rights reserved.
//

#import "ADBCopyFile.h"
#include <copyfile.h>

static int ADBCopyFileCallback(int what, int stage, copyfile_state_t state,
                               const char * src, const char * dst, void * ctx)
{
	ADBCopyFile *nsCtx = (__bridge ADBCopyFile *)(ctx);
	
	
	return COPYFILE_CONTINUE;
}


@implementation ADBCopyFile
{
    copyfile_state_t copyState;
}

-(instancetype)init
{
    if (self = [super init]) {
        copyState = copyfile_state_alloc();
		copyfile_state_set(copyState, COPYFILE_STATE_STATUS_CB, &ADBCopyFileCallback);
		copyfile_state_set(copyState, COPYFILE_STATE_STATUS_CTX, (__bridge CFTypeRef)(self));
    }
    return self;
}

-(void)dealloc
{
    copyfile_state_free(copyState);
}

@end
