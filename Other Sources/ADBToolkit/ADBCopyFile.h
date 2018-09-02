//
//  ADBCopyFile.h
//  Boxer
//
//  Created by C.W. Betts on 9/2/18.
//  Copyright © 2018 Alun Bestor and contributors. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, ADBCopyFileFlag) {
	ADBCopyFileFlagACL		= 1<<0,
	ADBCopyFileFlagPosix	= 1<<1,
	ADBCopyFileFlagXAttr	= 1<<2,
	ADBCopyFileFlagData		= 1<<3,

	ADBCopyFileFlagSecurity	= ADBCopyFileFlagPosix | ADBCopyFileFlagACL,
	ADBCopyFileFlagMetadata	= ADBCopyFileFlagSecurity | ADBCopyFileFlagXAttr,
	ADBCopyFileFlagAll		= ADBCopyFileFlagMetadata | ADBCopyFileFlagData,

	/** Descend into hierarchies */
	ADBCopyFileFlagRecursive	= 1<<15,
	/** return flags for xattr or acls if set */
	ADBCopyFileFlagCheck		= 1<<16,
	/** fail if destination exists */
	ADBCopyFileFlagExclusive	= 1<<17,
	/** don't follow if source is a symlink */
	ADBCopyFileFlagNoFollowSource	= 1<<18,
	/** don't follow if dst is a symlink */
	ADBCopyFileFlagNoFollowDest		= 1<<19,
	/** unlink src after copy */
	ADBCopyFileFlagMove		= 1<<20,
	/** unlink dst before copy */
	ADBCopyFileFlagUnlink	= 1<<21,
	/** don't follow if source or dst is a symlink */
	ADBCopyFileFlagNoFollow	= ADBCopyFileFlagNoFollowSource | ADBCopyFileFlagNoFollowDest,

	ADBCopyFileFlagPack		= (1<<22),
	ADBCopyFileFlagUnpack	= (1<<23),

	ADBCopyFileFlagNoClone		= (1<<24),
	ADBCopyFileFlagForceClone	= (1<<25),

	ADBCopyFileFlagRunInPlace	= (1<<26),

	ADBCopyFileFlagDataSparse	= (1<<27),

	ADBCopyFileFlagVerbose		= (1<<30)
};

typedef NS_ENUM(int, ADBCopyFileAction) {
	ADBCopyFileActionContinue = 0,
	ADBCopyFileActionSkip = 1,
	ADBCopyFileActionStop = 2
};

typedef NS_ENUM(int, ADBCopyFileStage) {
	ADBCopyFileStageStart = 1,
	ADBCopyFileStageFinish = 2,
	ADBCopyFileStageError = 3,
	ADBCopyFileStageProgress = 4
};

/*
 #define	COPYFILE_RECURSE_ERROR	0
 #define	COPYFILE_RECURSE_FILE	1
 #define	COPYFILE_RECURSE_DIR	2
 #define	COPYFILE_RECURSE_DIR_CLEANUP	3
 #define	COPYFILE_COPY_DATA	4
 #define	COPYFILE_COPY_XATTR	5
*/

@protocol ADBCopyFileDelegate;

@interface ADBCopyFile : NSObject

@end


@protocol ADBCopyFile <NSObject>

@end

