package ObmSatellite::Modules::backupEntity;

$VERSION = '1.0';

$debug = 1;

use 5.006_001;

use ObmSatellite::Modules::abstract;
@ISA = qw(ObmSatellite::Modules::abstract);
use strict;

eval {
    require ObmSatellite::Modules::BackupEntity::user;
    require ObmSatellite::Modules::BackupEntity::mailshare;
};

use File::Path;
use File::Copy;
use File::Find;

use HTTP::Status;
use ObmSatellite::Misc::constant;
use ObmSatellite::Misc::regex;

use constant OBM_BACKUP_ROOT => '/var/backup/obm';
use constant RECONSTRUCT_PATH => '/usr/lib/cyrus-imapd:/usr/lib/cyrus/bin';
use constant RECONSTRUCT_CMD => 'reconstruct';
use constant QUOTA_PATH => '/usr/lib/cyrus-imapd:/usr/lib/cyrus/bin';
use constant QUOTA_CMD => 'quota';

sub _setUri {
    my $self = shift;

    return [ '/backupentity', '/restoreentity', '/availablebackup' ];
}

sub _initHook {
    my $self = shift;

    $self->{'neededServices'} = [ 'LDAP', 'CYRUS' ];

    $self->{'backupRoot'} = OBM_BACKUP_ROOT;
    $self->{'imapdConfFile'} = IMAPD_CONF_FILE;
    $self->{'tmpDir'} = TMP_DIR;
    $self->{'tarCmd'} = OBM_TAR_COMMAND;


    # Load some options from module configuration file
    my @params = ( 'backupRoot', 'imapdConfFile', 'tmpDir', 'tarCmd' );
    my $confFileParams = $self->_loadConfFile( \@params );

    $self->_log( $self->getModuleName().' module configuration :', 4 );
    for( my $i=0; $i<=$#params; $i++ ) {
        $self->{$params[$i]} = $confFileParams->{$params[$i]} if defined($confFileParams->{$params[$i]});
        $self->_log( $params[$i].' : '.$self->{$params[$i]}, 4 ) if defined($self->{$params[$i]});
    }

    return 1;
}


sub _putMethod {
    my $self = shift;
    my( $requestUri, $requestBody ) = @_;

    if( $requestUri !~ /^\/backupentity\/(user|mailshare)\/([^\/]+)$/ ) {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Invalid URI '.$requestUri ],
            help => [ $self->getModuleName().' URI must be : /backupentity/<entity>/<login>@<realm>' ]
            } );
    }

    my $entity = $1;
    SWITCH: {
        if( $entity eq 'user' ) {
            $entity = ObmSatellite::Modules::BackupEntity::user->new( $2 );
            last SWITCH;
        }

        if( $entity eq 'mailshare' ) {
            $entity = ObmSatellite::Modules::BackupEntity::mailshare->new( $2 );
            last SWITCH;
        }

        return $self->_response( RC_NOT_FOUND, {
            content => [ 'Unknow entity \''.$entity.'\'' ]
            } );
    }

    if( !defined($entity) ) {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Invalid login '.$requestUri ],
            help => [ $self->getModuleName().' URI must be : /backupentity/'.$entity.'/<login>@<realm>' ]
            } );
    }

    if( my $result = $self->_isEntityExist( $entity ) ) {
        return $result;
    }

    if( !( $entity->setContent($self->_xmlContent( $requestBody )) ) ) {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Invalid request content' ],
            help => [ $self->getModuleName().' request content must use XML form' ]
            } );
    }


    if( my $return = $self->_setBackupRoot( $entity ) ) {
        return $return;
    }

    my $response = $self->_createArchive( $entity );
    

    $self->_removeTmpArchive( $entity );
    $self->_removeBackupBackupFile( $entity );
    $self->_purgeOldBackupFiles( $entity );

    if( !$response ) {
        $self->_log( 'Backup '.$entity->getLogin().'@'.$entity->getRealm().' successfully', 3 );
        $response = $self->_response( RC_OK, {
            content => [ 'Backup '.$entity->getLogin().'@'.$entity->getRealm().' successfully' ]
            } );
    }else {
        $self->_log( 'Fail to backup '.$entity->getLogin().'@'.$entity->getRealm(), 1 );
    }

    return $response;
}


sub _getMethod {
    my $self = shift;
    my( $requestUri, $requestBody ) = @_;

    if( $requestUri !~ /^\/availablebackup\/(user|mailshare)\/([^\/]+)$/ ) {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Invalid URI '.$requestUri ],
            help => [ $self->getModuleName().' URI must be : /restoreentity/<entity>/<login>@<realm>' ]
            } );
    }

    my $entity = $1;
    SWITCH: {
        if( $entity eq 'user' ) {
            $entity = ObmSatellite::Modules::BackupEntity::user->new( $2 );
            last SWITCH;
        }

        if( $entity eq 'mailshare' ) {
            $entity = ObmSatellite::Modules::BackupEntity::mailshare->new( $2 );
            last SWITCH;
        }

        return $self->_response( RC_NOT_FOUND, {
            content => [ 'Unknow entity \''.$entity.'\'' ]
            } );
    }

    if( !defined($entity) ) {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Invalid login '.$requestUri ],
            help => [ $self->getModuleName().' URI must be : /backupentity/'.$entity.'/<login>@<realm>' ]
            } );
    }

    if( my $result = $self->_isEntityExist( $entity ) ) {
        return $result;
    }

    if( my $return = $self->_setBackupRoot( $entity ) ) {
        return $return;
    }

    my $availableBackupFile = $self->_getAvailableBackupFile( $entity );

    if( ref($availableBackupFile) ne 'ARRAY' ) {
        return $availableBackupFile;
    }

    $self->_log( 'Getting available backup file for '.$entity->getLogin().'@'.$entity->getRealm().' successfully', 3 );
    return $self->_response( RC_OK, {
        backupFile => $availableBackupFile
    } );
}


sub _postMethod {
    my $self = shift;
    my( $requestUri, $requestBody ) = @_;

    if( $requestUri !~ /^\/restoreentity\/(user|mailshare)\/([^\/]+)(\/(mailbox|contact|calendar)){0,1}$/ ) {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Invalid URI '.$requestUri ],
            help => [ $self->getModuleName().' URI must be : /restoreentity/<entity>/<login>@<realm>[/[mailbox|contact|calendar]]' ]
            } );
    }

    my $entity = $1;
    my $data = $4;

    SWITCH: {
        if( $entity eq 'user' ) {
            $entity = ObmSatellite::Modules::BackupEntity::user->new( $2 );
            last SWITCH;
        }

        if( $entity eq 'mailshare' ) {
            $entity = ObmSatellite::Modules::BackupEntity::mailshare->new( $2 );
            last SWITCH;
        }

        return $self->_response( RC_NOT_FOUND, {
            content => [ 'Unknow entity \''.$entity.'\'' ]
            } );
    }

    if( !defined($entity) ) {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Invalid login '.$requestUri ],
            help => [ $self->getModuleName().' URI must be : /restoreentity/'.$entity.'/<login>@<realm>[/[mailbox|contact|calendar]]' ]
            } );
    }

    if( my $result = $self->_isEntityExist( $entity ) ) {
        return $result;
    }

    if( my $content = $self->_xmlContent( $requestBody ) ) {
        if( (ref($content->{'backupFile'}) eq 'ARRAY') && defined( $content->{'backupFile'}->[0] ) ) {
            $entity->setBackupName( $content->{'backupFile'}->[0] );
        }else {
            return $self->_response( RC_BAD_REQUEST, {
                content => [ 'Invalid request content' ],
                help => [ $self->getModuleName().' restore request content must have \'backupFile\' element' ]
                } );
        }
    }else {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Invalid request content' ],
            help => [ $self->getModuleName().' restore request content must use XML form' ]
            } );
    }

    if( my $return = $self->_setBackupRoot( $entity ) ) {
        return $return;
    }

    my $response = $self->_restoreFromArchive( $entity, $data );

    $self->_removeTmpArchive( $entity );

    return $response;
}


sub _isEntityExist {
    my $self = shift;
    my( $entity ) = @_;

    my $ldapFilter = $entity->getLdapFilter();

    my $ldapEntity = $self->_getLdapValues(
        $ldapFilter,
        [] );

    if( $#{$ldapEntity} != 0 ) {
        return $self->_response( RC_BAD_REQUEST, {
            content => [ 'Entity '.$entity->getLogin().'@'.$entity->getRealm().' doesn\'t exist in LDAP' ],
            } );
    }

    return undef;
}


sub _isEntityMailboxDefined {
    my $self = shift;
    my( $entity ) = @_;

    my $cyrusConn = $self->_getCyrusConn();
    if( !defined( $cyrusConn ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Can\'t connect to Cyrus service' ]
            } );
    }

    my @mailBox = $cyrusConn->listmailbox( $entity->getLogin().'@'.$entity->getRealm(), $entity->getMailboxPrefix() );
    if( $cyrusConn->error() ) {
        $self->_log( 'Cyrus error: '.$cyrusConn->error(), 0 );
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Cyrus error: '.$cyrusConn->error() ]
            } );
    }

    # Mailbox exist 
    if( $#mailBox != 0 ) {
        return $self->_response( RC_OK, {
            content => [ 'Mailbox '.$entity->getMailboxPrefix().$entity->getLogin().'@'.$entity->getRealm().' doesn\'t exist !' ]
            } );
    }

    return undef;
}


sub _setBackupRoot {
    my $self = shift;
    my( $entity ) = @_;

    $entity->setBackupRoot( $self->{'backupRoot'} );

    if( ! -d $entity->getBackupPath() ) {
        if( $self->_mkdir( $entity->getBackupPath() ) ) {
            return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                content => [ 'Can\'t create \''.$entity->getBackupPath().'\'' ]
                } );
        }
    }

    $self->_log( 'Backup path : '.$entity->getBackupPath(), 4 );
    $self->_log( 'Backup name : '.$entity->getBackupName(), 4 );

    return undef;
}


sub _backupBackupFile {
    my $self = shift;
    my( $entity ) = @_;

    my $backupFullPath = $entity->getBackupPath().'/'.$entity->getBackupName();
    my $backupFullPathBackup = $backupFullPath.'.backup';

    if( -e $backupFullPathBackup ) {
        $self->_log( 'Remove backuped backup file : '.$backupFullPathBackup, 5 );
        if( !unlink( $backupFullPathBackup ) ) {
            return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                content => [ 'Can\'t remove backuped backup file : '.$backupFullPathBackup ]
                } );
        }
    }
    
    if( -e $backupFullPath ) {
        $self->_log( 'Rename '.$backupFullPath.' to '.$backupFullPathBackup, 5 );
        if( !move( $backupFullPath, $backupFullPathBackup ) ) {
            return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                content => [ 'Can\'t rename '.$backupFullPath.' to '.$backupFullPathBackup ]
                } );
        }
    }

    return undef;
}


sub _removeBackupBackupFile {
    my $self = shift;
    my( $entity ) = @_;

    my $backupFullPath = $entity->getBackupPath().'/'.$entity->getBackupName();
    my $backupFullPathBackup = $backupFullPath.'.backup';

    if( -e $backupFullPathBackup ) {
        $self->_log( 'Remove backuped backup file '.$backupFullPathBackup, 5 );
        if( !unlink( $backupFullPathBackup ) ) {
            $self->_log( 'Fail to remove backuped backup file '.$backupFullPathBackup, 5 );
            return 1;
        }
    }else {
        $self->_log( $backupFullPathBackup.' not found', 5 );
        return 2;
    }

    return 0;
}


sub _restoreBackupBackupFile {
    my $self = shift;
    my( $entity ) = @_;

    my $backupFullPath = $self->getBackupPath().'/'.$self->getBackupName();
    my $backupFullPathBackup = $backupFullPath.'.backup';

    if( -e $backupFullPathBackup ) {
        $self->_log( 'Restore backuped backup file '.$backupFullPathBackup, 5 );
        if( !move( $backupFullPathBackup, $backupFullPath ) ) {
            $self->_log( 'Fail to restore backuped backup file '.$backupFullPathBackup, 5 );
            return 1;
        }
    }else {
        $self->_log( $backupFullPathBackup.' not found', 5 );
        return 2;
    }

    return 0;
}


sub _purgeOldBackupFiles {
    my $self = shift;
    my( $entity ) = @_;

    my $backupName = $entity->getBackupNamePrefix();

    opendir( DIR, $entity->getBackupPath() );
    my @userBackup = grep( /^$backupName/, readdir(DIR) );
    close(DIR);

    for( my $i=0; $i<=$#userBackup; $i++ ) {
        $userBackup[$i] =~ /^(.+)$/;
        $userBackup[$i] = $1;

        if( $userBackup[$i] ne $entity->getBackupName() ) {
            $self->_log( 'Remove old backup file '.$userBackup[$i], 5 );
            unlink( $entity->getBackupPath().'/'.$userBackup[$i] );
        }
    }
}


sub _writeArchive {
    my $self = shift;
    my( $entity ) = @_;

    my $backupFullPath = $entity->getBackupFileName();
    my $backupFullPathBackup = $backupFullPath.'.backup';

    if( my $result = $self->_backupBackupFile( $entity ) ) {
        return $result;
    }

    my $cmd = $self->{'tarCmd'}.' --ignore-failed-read -C '.$entity->getTmpBackupPath().' -czhf '.$backupFullPath.' . > /dev/null 2>&1';
    $self->_log( 'Executing '.$cmd, 4 );

    if( my $returnCode = system( $cmd ) ) {
        $returnCode = ($returnCode >> 8) & 0xffff;
        my $content = {
            content => [ 'Can\'t write backup archive '.$backupFullPath.' - Error: '.$returnCode ]
            };

        my $result = $self->_restoreBackupBackupFile( $entity );
        SWITCH: {
            if( $result == 1 ) {
                push( @{$content->{'content'}}, 'No backuped backup file found' );
                last SWITCH;
            }

            if( $result == 2 ) {
                push( @{$content->{'content'}}, 'Can\'t move backuped backup file from'.$backupFullPathBackup.' to '.$backupFullPath );
                last SWITCH;
            }

            push( @{$content->{'content'}}, 'Backuped backup file '.$backupFullPathBackup.' restored to '.$backupFullPath );
            last SWITCH;
        }

        return $self->_response( RC_INTERNAL_SERVER_ERROR, $content );
    }

    return undef;
}


sub _createArchive {
    my $self = shift;
    my( $entity ) = @_;

    $self->_log( 'Beginning backup for '.$entity->getLogin().'@'.$entity->getRealm(), 3 );

    if( my $result = $self->_prepareTmpArchive( $entity ) ) {
        return $result;
    }

    if( $self->_addIcs( $entity ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Can\'t add ICS file to archive' ]
            } );
    }

    if( $self->_addVcard( $entity ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Can\'t add VCARD file to archive' ]
            } );
    }

    if( $self->_addMailbox( $entity ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Can\'t add mailbox file to archive' ]
            } );
    }

    return $self->_writeArchive( $entity );
}


sub _mkdir {
    my $self = shift;
    my( $path ) = @_;
    my $errors = [];

    if( ! -d $path ) {
        $self->_log( 'Creating path \''.$path.'\'', 5 );

        eval {
            local $SIG{__WARN__} = undef;
            local $SIG{__DIE__} = undef;
            mkpath( $path,
                { error => \$errors } );
        };

        if( $#$errors >= 0 ) {
            return $errors;
        }
    }

    return undef;
}


sub _rmdir {
    my $self = shift;
    my( $path ) = @_;
    my $errors = [];

    if( -d $path ) {
        $self->_log( 'Removing path \''.$path.'\'', 5 );

        eval {
            local $SIG{__WARN__} = undef;
            local $SIG{__DIE__} = undef;
            rmtree( $path,
                { error => \$errors } );
        };

        if( $#$errors >= 0 ) {
            return $errors;
        }
    }

    return undef;
}


sub _mkSymlink {
    my $self = shift;
    my( $dstFile, $symlinkName )  = @_;

    if( !eval{ symlink("",""); 1 } ) {
        $self->_log( 'Symlinks must be possible file system !', 0 );
        return [ 'Symlinks must be possible on file system !' ];
    }

    if( (-e $symlinkName) && (!-l $symlinkName) ) {
        if( !unlink( $symlinkName ) ) {
            $self->_log( $symlinkName.' exist but isn\'t a symlink and can\'t be remove', 1 );
            return [ $symlinkName.' exist but isn\'t a symlink and can\'t be remove' ];
        }
    }

    if( -d $symlinkName ) {
        $self->_log( $symlinkName.' exist and is a diretory', 1 );
        return [ $symlinkName.' exist and is a diretory' ];
    }


    $self->_log( 'Creating link from '.$dstFile.' to '.$symlinkName, 5 );
    if( !symlink( $dstFile, $symlinkName ) ) {
        return [ 'Creating link from '.$dstFile.' to '.$symlinkName.' fail' ];
    }

    return undef;
}


sub _removeTmpArchive {
    my $self = shift;
    my( $entity ) = @_;

    if( $self->_rmdir( $entity->getTmpBackupPath() ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Fail to remove '.$entity->getTmpBackupPath() ]
            } );
    }

    return undef;
}


sub _prepareTmpArchive {
    my $self = shift;
    my( $entity ) = @_;

    $entity->setTmpBackupPath( $self->{'tmpDir'}.'/'.$entity->getEntityType().'_-_'.$entity->getRealm().'_-_'.$entity->getLogin() );
    if( -e $entity->getTmpBackupPath() ) {
        $self->_log( $entity->getTmpBackupPath().' already exist !', 1 );
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                    content => [ $entity->getTmpBackupPath().' already exist !' ]
                    } );
    }

    $self->_log( 'Temporary backup path: '.$entity->getTmpBackupPath(), 4 );

    if( $entity->getTmpIcsPath() && $self->_mkdir( $entity->getTmpIcsPath() ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Fail to create '.$entity->getTmpIcsPath() ]
            } );
    }

    if( $entity->getTmpVcardPath() && $self->_mkdir( $entity->getTmpVcardPath() ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Fail to create '.$entity->getTmpVcardPath() ]
            } );
    }

    if( $entity->getTmpMailboxPath() && $self->_mkdir( $entity->getTmpMailboxPath() ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Fail to create '.$entity->getTmpMailboxPath() ]
            } );
    }

    return undef;
}


sub _addIcs {
    my $self = shift;
    my( $entity ) = @_;

    if( !$entity->getIcs() ) {
        return undef;
    }

    if( !open( FIC,
            '>:encoding(UTF-8)',
            $entity->getTmpIcsFile() ) ) {
        $self->_log( $!, 1 );
        return 1;
    }

    $self->_log( 'Writing ICS file '.$entity->getTmpIcsFile(), 5 );
    print FIC $entity->getIcs();
    close(FIC);

    return 0;
}


sub _addVcard {
    my $self = shift;
    my( $entity ) = @_;

    if( !$entity->getVcard() ) {
        return undef;
    }

    if( !open( FIC,
            '>:encoding(UTF-8)',
            $entity->getTmpVcardFile() ) ) {
        $self->_log( $!, 1 );
        return 1;
    }

    $self->_log( 'Writing VCARD file '.$entity->getTmpVcardFile(), 5 );
    print FIC $entity->getVcard();
    close(FIC);

    return 0;
}


sub _addMailbox {
    my $self = shift;
    my( $entity ) = @_;

    if( my $result = $self->_isEntityMailboxDefined($entity) ) {
        if( $result->isError() ) {
            return $result;
        }

        $self->_log( 'Mailbox \''.$entity->getLogin().'@'.$entity->getRealm().'\'isn\'t backuped', 4 );
        $self->_log( $result->asString(), 5 );
        return undef;
    }

    if( my $result = $self->_getCyrusPartitionPath( $entity ) ) {
        return $result;
    }

    my $mailboxRoot = $entity->getCyrusMailboxRoots();
    for( my $i=0; $i<=$#{$mailboxRoot}; $i++ ) {
        my $linkRoot = $mailboxRoot->[$i]->{'backup'};
        $linkRoot =~ /^(.+)\/[^\/]+$/;
        $linkRoot = $1;

        if( $self->_mkdir( $linkRoot ) ) {
            return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                content => [ 'Can\'t create \''.$linkRoot.'\'' ]
                } );
        }

        if( $self->_mkSymlink( $mailboxRoot->[$i]->{'cyrus'}, $mailboxRoot->[$i]->{'backup'} ) ) {
            return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                content => [ 'Can\'t create mailbox backup link '.$mailboxRoot->[$i]->{'backup'}.' to '.$mailboxRoot->[$i]->{'cyrus'} ]
                } );
        }
    }

    return undef;
}


sub _getCyrusPartitionPath {
    my $self = shift;
    my( $entity ) = @_;

    my $imapPartitionName = $entity->getRealm();
    $imapPartitionName =~ s/[\.-]/_/g;
    $imapPartitionName = 'partition-'.$imapPartitionName;
    $self->_log( 'Cyrus partition name : \''.$imapPartitionName.'\'', 5 );

    if( !open( FIC, $self->{'imapdConfFile'} ) ) {
        $self->_log( 'Can\'t open '.$self->{'imapdConfFile'}, 0 );
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Can\'t open '.$self->{'imapdConfFile'} ]
            } );
    }

    my $cyrusPartitionPath;
    while( !$cyrusPartitionPath && (my $line = <FIC>) ) {
        if( $line =~ /^$imapPartitionName:(\s)*([^\s]+)$/ ) {
            $cyrusPartitionPath = $2;
        }
    }

    close(FIC);

    if( !$cyrusPartitionPath ) {
        $self->_log( 'Can\'t find partition path for cyrus parition', 1 );
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Can\'t find partition path for cyrus parition' ]
            } );
    }

    $entity->setCyrusPartitionPath( $cyrusPartitionPath );

    $self->_log( 'Cyrus partition path : \''.$entity->getCyrusPartitionPath().'\'', 5 );

    return undef;
}


sub _getAvailableBackupFile {
    my $self = shift;
    my( $entity ) = @_;

    my $backupNamePrefix = $entity->getBackupNamePrefix();

    opendir( DIR, $entity->getBackupPath() ) or return $self->_response(
        RC_INTERNAL_SERVER_ERROR, {
        content => [ 'Can\'t open backup path '.$entity->getBackupPath() ]
        } );
    my @availableBackup = grep( /^$backupNamePrefix/, readdir(DIR) );
    close(DIR);

    return \@availableBackup;
}


sub _restoreFromArchive {
    my $self = shift;
    my( $entity, $restoreData ) = @_;

    if( !defined($restoreData) || ($restoreData !~ /^(mailbox|contact|calendar)$/) ) {
        $restoreData = 'all';
    }

    if( my $result = $self->_prepareTmpArchive( $entity ) ) {
        return $result;
    }

    if( my $result = $self->_getFilesFromArchive( $entity, $restoreData ) ) {
        return $result;
    }

    return $self->_response( RC_OK, $entity->getEntityContent() );
}


sub _getFilesFromArchive {
    my $self = shift;
    my( $entity, $restoreData ) = @_;

    my $entityArchive = $entity->getBackupFileName();
    if( !(-f $entityArchive) || !(-r $entityArchive) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Entity archive \''.$entityArchive.'\' doesn\'t exist or isn\'t readable' ]
            } );
    }

    $self->_log( 'Beginning \''.$restoreData.'\' restore for '.$entity->getLogin().'@'.$entity->getRealm(), 3 );

    if( my $result = $self->_getIcsVcardFromArchive( $entity, $restoreData ) ) {
        return $result;
    }

    if( my $result = $self->_restoreMailbox( $entity, $restoreData ) ) {
        return $result;
    }

    $self->_log( 'Restore \''.$restoreData.'\' for '.$entity->getLogin().'@'.$entity->getRealm().' successfully', 3 );
    return undef;
}


sub _getIcsVcardFromArchive {
    my $self = shift;
    my( $entity, $restoreData ) = @_;

    my @extractedFiles;
    if( $restoreData =~ /^(all|calendar)$/ ) {
        if( defined($entity->getArchiveIcsPath()) ) {
            push( @extractedFiles, $entity->getArchiveIcsPath() );
        }
    }

    if( $restoreData =~ /^(all|contact)$/ ) {
        if( defined($entity->getArchiveVcardPath()) ) {
            push( @extractedFiles, $entity->getArchiveVcardPath() );
        }
    }

    if( $#extractedFiles < 0 ) {
        return undef;
    }

    my $cmd = $self->{'tarCmd'}.' -C '.$entity->getTmpBackupPath().' -xzf '.$entity->getBackupFileName().' '.join( ' ', @extractedFiles).' > /dev/null 2>&1';
    $self->_log( 'Executing '.$cmd, 4 );

    if( my $returnCode = system( $cmd ) ) {
        $returnCode = ($returnCode >> 8) & 0xffff;
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                    content => [ 'Can\'t extract files from backup archive '.$entity->getTmpBackupPath().' - Error: '.$returnCode ]
                    } );
    }

    if( $restoreData =~ /^(all|calendar)$/ ) {
        if( (-e $entity->getTmpIcsFile()) && !(-f $entity->getTmpIcsFile()) ) {
            return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                        content => [ 'Can\'t load extracted ICS file from '.$entity->getTmpIcsFile() ]
                        } );
        }

        open( FIC, $entity->getTmpIcsFile() );
        my @ics = <FIC>;
        close(FIC);

        $entity->setIcs( join( '', @ics ) );
    }

    if( $restoreData =~ /^(all|contact)$/ ) {
        if( (-e $entity->getTmpVcardFile()) && !(-f $entity->getTmpVcardFile()) ) {
            return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                        content => [ 'Can\'t load extracted ICS file from '.$entity->getTmpVcardFile() ]
                        } );
        }

        open( FIC, $entity->getTmpVcardFile() );
        my @ics = <FIC>;
        close(FIC);

        $entity->setVcard( join( '', @ics ) );
    }

    return undef;
}


sub _restoreMailbox {
    my $self = shift;
    my( $entity, $restoreData ) = @_;

    if( $restoreData !~ /^(all|mailbox)$/ ) {
        return undef;
    }

    if( my $result = $self->_getCyrusPartitionPath( $entity ) ) {
        return $result;
    }

    if( my $result = $self->_createRestoreMailboxFolder( $entity ) ) {
        return $result;
    }

    return undef;
}


sub _createRestoreMailboxFolder {
    my $self = shift;
    my( $entity, $retry ) = @_;

    if( !$retry ) {
        $retry = 0;

        if( my $result = $self->_isEntityMailboxDefined($entity) ) {
            if( $result->isError() ) {
                return $result;
            }
    
            $self->_log( 'Mailbox \''.$entity->getLogin().'@'.$entity->getRealm().'\' isn\'t restored', 4 );
            $self->_log( $result->asString(), 5 );
            return undef;
        }
    }

    my $cyrusConn = $self->_getCyrusConn();
    if( !defined( $cyrusConn ) ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Can\'t connect to Cyrus service' ]
            } );
    }

    my @mailBox = $cyrusConn->listmailbox( $entity->getMailboxRestoreFolder(), $entity->getMailboxPrefix() );
    if( $cyrusConn->error() ) {
        $self->_log( 'Cyrus error: '.$cyrusConn->error(), 0 );
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Cyrus error: '.$cyrusConn->error() ]
            } );
    }

    # If mailbox already exist, retry with another mailbox name
    if( ($#mailBox >= 0) && ($retry < 5) ) {
        return $self->_createRestoreMailboxFolder($entity, $retry++);
    }

    if( $retry >= 5 ) {
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Can\'t find a valid mailbox folder to restore data' ]
            } );
    }


    # Creating restore mailbox
    $self->_log( 'Create mailbox: '.$entity->getMailboxPrefix().$entity->getMailboxRestoreFolder(), 4 );

    $cyrusConn->create( $entity->getMailboxPrefix().$entity->getMailboxRestoreFolder() );
    if( $cyrusConn->error() ) {
        $self->_log( 'Fail to create mailbox \''.$entity->getMailboxPrefix().$entity->getMailboxRestoreFolder().'\': '.$cyrusConn->error() );
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
            content => [ 'Fail to create mailbox \''.$entity->getMailboxPrefix().$entity->getMailboxRestoreFolder().'\': '.$cyrusConn->error() ]
            } );
    }


    # Restore mailbox content
    my $cmd = $self->{'tarCmd'}.' --strip '.$entity->getRestoreMailboxArchiveStrip().' -C '.$entity->getMailboxRestorePath().' -xzf '.$entity->getBackupFileName().' '.$entity->getArchiveMailboxPath().' > /dev/null 2>&1';
    $self->_log( 'Executing '.$cmd, 4 );

    if( my $returnCode = system( $cmd ) ) {
        $returnCode = ($returnCode >> 8) & 0xffff;
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                    content => [ 'Can\'t extract files from backup archive '.$entity->getTmpBackupPath().' - Error: '.$returnCode ]
                    } );
    }

    my $contentUid = (stat($entity->getMailboxRestorePath()))[4];
    my $contentGid = (stat($entity->getMailboxRestorePath()))[5];
    my $mailboxRestorePath = $entity->getMailboxRestorePath();
    find( {
            wanted => sub {
                my $path = $_;
                if( $path =~ /^($mailboxRestorePath\/(.+\/)*(cyrus\..+|[0-9]+\.))$/ ) {
                    chown( $contentUid, $contentGid, $1 );
                    chmod( 0600, $1 );
                }
            },
            no_chdir  => 1
        }, $entity->getMailboxRestorePath() );

    my $reconstructMailbox = $entity->getMailboxPrefix().$entity->getMailboxRestoreFolder();
    $reconstructMailbox =~ s/^(.+)@/$1\*@/;
    $cmd = 'su -l -c \'PATH="'.RECONSTRUCT_PATH.'" '.RECONSTRUCT_CMD.' -r -f -x '.$reconstructMailbox.'\' cyrus';
    $self->_log( 'Executing '.$cmd, 4 );

    if( my $returnCode = system($cmd) ) {
        $returnCode = ($returnCode >> 8) & 0xffff;
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                    content => [ 'Can\'t reconstruct restore mailbox \''.$reconstructMailbox.'\' - Error: '.$returnCode ]
                    } );
    }

    $cmd = 'su -l -c \'PATH="'.QUOTA_PATH.'" '.QUOTA_CMD.' -d '.$entity->getRealm().' '.$entity->getMailboxPrefix().$entity->getLogin().'\' cyrus';
    $self->_log( 'Executing '.$cmd, 4 );

    if( my $returnCode = system($cmd) ) {
        $returnCode = ($returnCode >> 8) & 0xffff;
        return $self->_response( RC_INTERNAL_SERVER_ERROR, {
                    content => [ 'Can\'t refresh quota for '.$entity->getLogin().'@'.$entity->getRealm().' - Error: '.$returnCode ]
                    } );
    }

 
    return undef;
}


# Perldoc

=head1 NAME

BackupEntity obmSatellite module

=head1 SYNOPSIS

This module backup entity data.

This module is XML/HTTP REST compliant.

=head1 COMMAND

=over 4

=item B<PUT /backupentity>/<entity>/<login>@<realm> : backup login entity data.

=over 4

=item PUT data : none

=item Return success or fail status

=back

=back
