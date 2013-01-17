package Blogg::Admin::Imgbrowser;
use Mojo::Base ('Mojolicious::Controller');
use Db;
use utf8;

my $currentDir;

sub index {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    $currentDir = "/images/Friaar/";

    $self->app->log->debug(getFolders("/"));
    $self->app->log->debug(getFiles("/"));
    my $content = { folders => getFolders($currentDir), files => getFiles($currentDir) };
    $self->stash(content => $content);

    $self->render('/admin/imgbrowser');
}

sub changeDir {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    my $newdir = $self->param('newdir');

    updateCurrentDir($newdir);
    my $content = { folders => getFolders($currentDir), files => getFiles($currentDir) };

    $self->render(json => $content);
}

sub updateDescription {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    my $imgname = $self->param('filename');
    my $newdesc = $self->param('description');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $response = Db::updateImgDescription($imgname, $newdesc);
    Db::disconnect();

    $self->render(json => $response);
}

sub updateCurrentDir {
    my $newdir = shift;

    if ( $newdir eq ".." ) {
        if($currentDir =~ m/^\/[^\/]*\/$/) {
            $currentDir = "/";
        } else {
            $currentDir =~ s/^(\/.*\/)[^\/]*\/$/$1/;   
        }
    } elsif ( -d "public$currentDir/$newdir" ) {
        $currentDir .= "$newdir/";
    }
}

sub getFolders {
    my $dir = shift;

    my @folders = `ls -d public$dir*/`;
    my $json = [];
    unshift @folders, ".." if length $currentDir > 1;
    for ( @folders ) {
        s/^.*\/([^\/]*)\/$/$1/;
        chomp;
        push @$json, { "name" => $_ };
     }

    return $json;
}

sub getFiles {
    my $dir = shift;
    my @files = `ls -F public$dir | grep -v /`;
    my $json = [];
    my ($travel, $tag) = ($1, $2) if $dir =~ m/^\/images\/([^\/]*)\/([^\/]*)\/$/; 

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $descriptons = Db::getImgDescriptions($travel, $tag);
    Db::disconnect();

    for my $file ( @files ) {
        my $temp = {};
        chomp $file;
        $temp->{'name'} = $file;

        if ($file =~ m/\.jpg/i and $dir =~ m/^\/images\/([^\/]*)\/([^\/]*)\/$/) {
            $temp->{'type'} = "image";
            $temp->{'thumb'} = "/images/$1/$2/thumbs/thumb_$file";
            $temp->{'description'} = $descriptons->{$file}; 
        } else {
            $temp->{'type'} = "file";
        }
        push @$json, $temp;
    }

    return $json;
}

1;
