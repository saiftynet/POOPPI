#!/usr/bin/env perl
use strict; use warnings;
use lib "./lib/"; 
use Term::ReadKey;     
use Object::Pad;
use Time::HiRes ("sleep");      # allow fractional sleeps 
use utf8;                       # allow utf characters in print
binmode STDOUT, ":utf8";


my $sprite=Sprite->new(x=>20, y=>19, dx=>1, dy=>.5,ddx=>0, ddy=>0, maxX=>70,minX=>10, maxY=>19,minY=>4, mass=>1,
	        spriteData=>[[qw/▟ ▙ /],[qw/▜ ▛/]],
	        spriteColour=>[["red","yellow"],["green", "blue"]]);

my $bat1=Sprite->new(x=>10, y=>10, dx=>0, dy=>0,ddx=>0, ddy=>0, maxX=>12,minX=>10, maxY=>18,minY=>4, mass=>1,
	        spriteData=>[[qw/◢ ◣/],[qw/▮ ▮/],[qw/▮ ▮/],[qw/◥ ◤/]],
	        spriteColour=>[["cyan",""],["white", ""],["white", ""],["cyan", ""]]);
$bat1->paint();
my $bat2=Sprite->new(x=>68, y=>10, dx=>0, dy=>0,ddx=>0, ddy=>0, maxX=>12,minX=>10, maxY=>18,minY=>4, mass=>1,
	        spriteData=>[[qw/◢ ◣/],[qw/▮ ▮/],[qw/▮ ▮/],[qw/◥ ◤/]],
	        spriteColour=>[["cyan",""],["white", ""],["white", ""],["cyan", ""]]);
$bat2->paint();

my $player1= {name=>"Player1",score=>0};
my $player2= {name=>"Player2",score=>0};

my $keyActions={
    65=>sub{
		$bat2->step(0,-2) unless ($bat2->atEdge()=~/[T]/);
	},
	66=>sub{
		$bat2->step(0,2) unless ($bat2->atEdge()=~/[B]/);
	},
	97=>sub{
		$bat1->step(0,-2) unless ($bat1->atEdge()=~/[T]/);
	},
	122=>sub{
		$bat1->step(0,2) unless ($bat1->atEdge()=~/[B]/);
	},	
	113=>sub{
		ReadMode 'normal';
		exit;
	},	
};

 playGame();
 

sub playGame{
	ReadMode 'cbreak';
	my $t=0;
	Display::drawBox(2,9,22,70);
	while (1){
		$sprite->wipe();
		$bat1->wipe();
		$bat2->wipe();
		$sprite->edgeReflect;
		if ($sprite->collide($bat1)||$sprite->collide($bat2)){
			$sprite->reflectXAngled($sprite->x<20?$bat1:$bat2) 
			};
		$sprite->move() unless $t % 3;
		updateScores()  if ($sprite->atEdge() =~/[LR]/);
		$sprite->rotate($sprite->spriteColour,90) unless $t%5;
		$sprite->paint();
		$sprite->draw();
		keyAction();
		$bat1->draw();
		$bat2->draw();

		
		sleep .05;
	}
   ReadMode 'normal';
   
   sub updateScores{
	   my $x;
	   if ($sprite->atEdge() =~/[R]/){
		   $player1->{score}+=1;
		   $x=20;
		   } 
	   else{
		   $player2->{score}+=1;
		   $x=50;
		   };
	   $sprite->wipe();
	   $sprite->place($x,$sprite->y);
	   Display::printAt(10,22, Display::bigDigit($player1->{score},"red")); 
	   Display::printAt(10,57,  Display::bigDigit($player2->{score},"green"));
	   
	   $sprite->draw();
	   sleep 1;
	   while(ReadKey(-1)){};  # empty key buffer
	   while(! ReadKey(-1)){};# wait for key press
	   
   }
}



sub keyAction{
	  my $key = ReadKey(-1);                # -1 means non-blocking read
	  if ($key){
		my $OrdKey = ord($key);
		Display::printAt (23,30,"key pressed=$OrdKey");
		$keyActions->{$OrdKey}->() if (exists $keyActions->{$OrdKey});
	  }  
}


class Sprite{

   has $x         :reader :writer :param = 0 ;
   has $y         :reader :writer :param = 0 ;
   has $dx        :reader :writer :param = 0 ;
   has $dy        :reader :writer :param = 0 ;
   has $ddx      :param = 0;
   has $ddy      :param = 0;
   has $maxX     :param = 79;
   has $minX     :param = 0;
   has $maxY     :param = 23;
   has $minY     :param = 20;
   has $mass     :param = 1;            
   has $spriteData     :reader :param;          # required
   has $spriteColour   :reader :param = undef;  # not required
   has $paintedSprite;                  # generated internally
 


method paint{
	my @painted;
	foreach my $r(0..$self->height()-1){
		$painted[$r]=[];
		foreach my $c(0..$self->width()-1){
			$painted[$r]=[@{$painted[$r]}, Display::paintChar($spriteData->[$r]->[$c],$spriteColour->[$r]->[$c])] ;
	    }
	}
	$paintedSprite=\@painted;
}

method draw{
	my $blit="\033[?25l";
	my @sd=map  {join ("",@{$_})} @{$paintedSprite};
	Display::printAt($y,$x,@sd,Display::colour("reset"));
}


method wipe{  # draws over a sprite with spaces of the same rectangle
	my @blanks=(" " x length ($spriteData->[0])) x @{$spriteData};
	Display::printAt($y,$x,@blanks);
}

method move{
	$x+=$dx;
	$y+=$dy;
}

method step{
	my ($stepX,$stepY)=@_;
	$x+=$stepX;
	$y+=$stepY;
}

method place{
	my ($posX,$posY)=@_;
	$x=$posX;
	$y=$posY;
}

method reflectX{
	$dx=-$dx;	
}

method reflectY{
	$dy=-$dy;	
}

method atEdge{
	my $edge="";	
	$edge.= "L" if ( $x<=$minX);
	$edge.= "T" if ( $y<=$minY);
	$edge.= "R" if ( $x>=$maxX);
	$edge.= "B" if ( $y>=$maxY);
	return $edge;
}

method width{
	return scalar @{$self->spriteData->[0]}
}

method height{
	return scalar @{$self->spriteData}
}

method edgeReflect{
	my $edge=atEdge($self);
	$dy =  abs ($dy) if ($edge=~/T/);	
	$dy = -abs ($dy) if ($edge=~/B/);
	$dx =  abs ($dx) if ($edge=~/L/);	
	$dx = -abs ($dx) if ($edge=~/R/);	
}

method reflectXAngled{ #refkecting $self according to dCog between $b and $self
	my ($b)=@_;
	die unless $b;
	$dy=(${$self->dCog($b)}[1]/3);
	$self->reflectX();
}

method collide{ # detect contact with sprite $b
	my ($b)=@_;
	my  ($ax1,$ax2,$ay1,$ay2,$bx1,$bx2,$by1,$by2) =
	    ($x,$x+$self->width(),
	     $y,$y+$self->height(),
	     $b->x,$b->x+$b->width(),
	     $b->y,$b->y+$b->height()  );
	
	return (($ax1 <= $bx2) && ($ax2 >= $bx1) && ($ay1 <= $by2) && ($ay2 >= $by1) ) 
}


method cog{  # center of gravity guesstimate
	return [$x+$self->width()/2,
	        $y+$self->height()/2]
}

method dCog{ # displacement of cogs $b vs $self;
	my ($b)=@_;
	die unless $b;
	my ($cogA,$cogB)=($self->cog(),$b->cog());
	return [$cogA->[0]-$cogB->[0],$cogA->[1]-$cogB->[1]];
}

##generic matrix manipulation

method flipV{
	my $matrix=shift;	
	@$matrix=reverse @$matrix;  #$matrix=[reverse @$matrix] doesnt work...
}

method flipH{
	my $matrix=shift;	
	$matrix->[$_]=[reverse @{$matrix->[$_]}] foreach(0..(scalar @{$matrix}-1));
}
method transpose{
	my $matrix=shift;
	my $columns=scalar @{$matrix->[0]};
	my $rows=scalar @$matrix;
	my $transposed;
	foreach my $c(0..$columns-1){
		$$transposed[$c]=[];
		foreach my $r(0..$rows-1){
			$$transposed[$c][$r]=$$matrix[$r][$c];
	    }
	}
	@$matrix=@$transposed;	
}

method rotate{
	my ($matrix,$rotation)=@_;
	if ($rotation=~/^cw|90$/){
		$self->transpose($matrix);
		$self->flipV($matrix);
	}
	elsif ($rotation=~/^180/){
		$self->flipV($matrix);
		$self->flipH($matrix);
	}
	elsif ($rotation=~/^cxw|270$/){
		$self->transpose($matrix);
		$self->flipH($matrix);
	}
}



}





package Display;

sub paintChar{
	my ($char,$colour)=@_;
	return colour($colour).$char;
}


sub drawBox{
	my($top,$left,$bottom,$right)=@_;
	printAt($top,$left,"▛".("▀"x ($right-$left))."▜");
	printAt($bottom,$left,"▙".("▄"x ($right-$left))."▟");
}

sub printAt{
  my ($row,$column,@textRows)=@_;
  $row=int($row);
  $column=int($column);
  return unless (@textRows||$textRows[0]);
  @textRows = @{$textRows[0]} if ref $textRows[0];  
  my $blit="\033[?25l";
   foreach (@textRows){
       $blit.= "\033[".$row++.";".$column."H".$_ unless ($row>22)
   }
  print $blit;
  print "\n"; # seems to flush the STDOUT buffer...if not then set $| to 1 
};

sub stripColours{
  my $line=shift;
  $line=~s/\033\[[^m]+m//g;
  return $line;
}

sub colour{
  my ($fmts)=@_;
  return "" unless $fmts;
  return "" if ($^O =~/Win/);
  my @formats=map {lc $_} split / +/,$fmts;   
  my %colours=(black   =>30,red   =>31,green   =>32,yellow   =>33,blue   =>34,magenta   =>35,cyan  =>36,white   =>37,
               on_black=>40,on_red=>41,on_green=>42,on_yellow=>43,on_blue=>44,on_magenta=>4,on_cyan=>46,on_white=>47,
               reset=>0, bold=>1, italic=>3, underline=>4, strikethrough=>9,);
  return join "",map {defined $colours{$_}?"\033[$colours{$_}m":""} @formats;
}


sub bigDigit{
	my $bigDigits=
	[["▞▚ ","▞▌  ", "▞▚ ","▞▚ ",  " ▞▌" ,"▛▀  ","▞▚ ","▀▜ ","▞▚ ","▞▚ "],
	 ["▌▐ ", " ▌  ", "▗▞ ", " ▚ ", "▟▄▙" ,"▀▚  ","▙▖ ", " ▞ ","▞▚ ","▝▜ "],
	 ["▚▞ ","▄▙▖ ","▙▄ ","▚▞ ",   "  ▌ ","▚▞  ","▚▞ ","▞   ","▚▞ ", "▚▞ "]];

	my($number,$colour)=@_;
	my @row=(colour($colour),"","");
	foreach my $digit (split("",$number)){
		foreach (0..2){
		   $row[$_].=$bigDigits->[$_]->[$digit];
	    }
	}
	$row[2]=$row[2].colour("reset");
	return \@row;
}



1;
