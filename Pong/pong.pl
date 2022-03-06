#!/usr/bin/env perl
use strict; use warnings;
use lib "./lib/"; 
use Term::ReadKey;     
use Object::Pad;
use Time::HiRes ("sleep");      # allow fractional sleeps 
use utf8;                       # allow utf characters in print
binmode STDOUT, ":utf8";


my $sprite={x=>20, y=>19, dx=>1, dy=>.5,ddx=>0, ddy=>0, maxX=>70,minX=>10, maxY=>20,minY=>4, mass=>1,
	        spriteData=>[[qw/▟ ▙ /],[qw/▜ ▛/]],
	        spriteColour=>[["red","yellow"],["green", "blue"]]};
paintSprite($sprite);

my $bat1={x=>10, y=>10, dx=>0, dy=>0,ddx=>0, ddy=>0, maxX=>12,minX=>10, maxY=>18,minY=>4, mass=>1,
	        spriteData=>[[qw/◢ ◣/],[qw/▮ ▮/],[qw/▮ ▮/],[qw/◥ ◤/]],
	        spriteColour=>[["cyan",""],["white", ""],["white", ""],["cyan", ""]]};
paintSprite($bat1);

my $bat2={x=>68, y=>10, dx=>0, dy=>0,ddx=>0, ddy=>0, maxX=>12,minX=>10, maxY=>18,minY=>4, mass=>1,
	        spriteData=>[[qw/◢ ◣/],[qw/▮ ▮/],[qw/▮ ▮/],[qw/◥ ◤/]],
	        spriteColour=>[["cyan",""],["white", ""],["white", ""],["cyan", ""]]};
paintSprite($bat2);

my $player1= {name=>"Player1",score=>0};
my $player2= {name=>"Player2",score=>0};

my $bigDigits=
	[["▞▚ ","▞▌  ","▞▚ ","▞▚ ", " ▞▌" ,"▛▀  ","▞▚ ","▀▜ ","▞▚ ","▞▚ "],
	 ["▌▐ ", " ▌  ","▗▞ ", " ▚ ","▟▄▙" ,"▀▚  ","▙▖ ", " ▞ ","▞▚ ","▝▜ "],
	 ["▚▞ ","▄▙▖","▙▄ ","▚▞ ",  "  ▌ ","▚▞  ","▚▞ ","▞   ","▚▞ ","▚▞ "]];

sub bigDigit{
	my($digit,$colour)=@_;
	my $d=[colour($colour).$bigDigits->[0]->[$digit],$bigDigits->[1]->[$digit],$bigDigits->[2]->[$digit].colour("reset")];
	return $d;
}

my $keyActions={
    65=>sub{
		stepSprite($bat2,0,-2) unless (atEdge($bat2)=~/[T]/);
	},
	66=>sub{
		stepSprite($bat2,0,2) unless (atEdge($bat2)=~/[B]/);
	},
	97=>sub{
		stepSprite($bat1,0,-2) unless (atEdge($bat1)=~/[T]/);
	},
	122=>sub{
		stepSprite($bat1,0,2) unless (atEdge($bat1)=~/[B]/);
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
	drawBox(2,9,22,70);
	while (1){
		wipeSprite($sprite);
		wipeSprite($bat1);
		wipeSprite($bat2);
		edgeReflect($sprite);
		#reflectX($sprite) if (atEdge($sprite) =~/[R]/);
		#reflectY($sprite) if (atEdge($sprite) =~/[TB]/);
		if (collide($bat1,$sprite)||collide($bat2,$sprite)){
			#die "dCog with bat1 is ".dCog($bat1,$sprite)->[1]. " dCog with bat2 is ".dCog($bat2,$sprite)->[1];  
			reflectXAngled($sprite->{x}<20?$bat1:$bat2,$sprite) 
			};
		moveSprite($sprite) unless $t % 3;
		updateScores()  if (atEdge($sprite) =~/[LR]/);
		rotate($sprite->{spriteColour},90) unless $t%5;
		paintSprite($sprite);
		drawSprite($sprite);
		keyAction();
		drawSprite($bat1);
		drawSprite($bat2);

		
		sleep .05;
	}
   ReadMode 'normal';
   
   sub updateScores{
	   my $x;
	   if (atEdge($sprite) =~/[R]/){
		   $player1->{score}+=1;
		   $x=20;
		   } 
	   else{
		   $player2->{score}+=1;
		   $x=50;
		   };
	   wipeSprite($sprite);
	   placeSprite($sprite, $x,$sprite->{y});
	   printAt(10,22, bigDigit($player1->{score},"red")); 
	   printAt(10,57, bigDigit($player2->{score},"green"));
	   
	   drawSprite($sprite);
	   sleep 1;
	   while(ReadKey(-1)){};  # empty key buffer
	   while(! ReadKey(-1)){};# wait for key press
	   
   }
}


sub drawSprite{
	my $s=shift;
	my $blit="\033[?25l";
	my @sd=map  {join ("",@{$_})} @{$s->{paintedSprite}};
	printAt($s->{y},$s->{x},@sd,colour("reset"));
}

sub paintSprite{
	my $s=shift;
	my @painted;
	my $width=scalar @{$$s{spriteData}[0]};
	my $height=scalar @{$$s{spriteData}};
	foreach my $r(0..$height-1){
		$painted[$r]=[];
		foreach my $c(0..$width-1){
			$painted[$r]=[@{$painted[$r]}, paintChar($s->{spriteData}->[$r]->[$c],$s->{spriteColour}->[$r]->[$c])] ;
	    }
	}
	
	$s->{paintedSprite}=\@painted;
}

sub paintChar{
	my ($char,$colour)=@_;
	return colour($colour).$char;
}

sub wipeSprite{  # draws over a sprite with spaces of the same rectangle
	my $s=shift;
	my @blanks=(" " x length ($$s{spriteData}[0])) x @{$$s{spriteData}};
	printAt($$s{y},$$s{x},@blanks);
}

sub moveSprite{
	my $s=shift;
	$$s{x}+=$$s{dx};
	$$s{y}+=$$s{dy};
}

sub stepSprite{
	my ($s,$x,$y)=@_;
	$$s{x}+=$x;
	$$s{y}+=$y;
}

sub placeSprite{
	my ($s,$x,$y)=@_;
	$$s{x}=$x;
	$$s{y}=$y;
}

sub collide{ # detect contact
	my ($a,$b)=@_;
	my  ($ax1,$ax2,$ay1,$ay2,$bx1,$bx2,$by1,$by2) =
	    ($a->{x},$a->{x}+scalar @{$a->{spriteData}->[0]},
	     $a->{y},$a->{y}+scalar @{$a->{spriteData}},
	     $b->{x},$b->{x}+scalar @{$b->{spriteData}->[0]},
	     $b->{y},$b->{y}+scalar @{$b->{spriteData}});
	
	return (($ax1 <= $bx2) && ($ax2 >= $bx1) && ($ay1 <= $by2) && ($ay2 >= $by1) ) 
	
}

sub cog{  # center of gravity guesstimate
	my $s=shift;
	return [$s->{x}+(scalar @{$s->{spriteData}->[0]})/2,
	        $s->{y}+(scalar @{$s->{spriteData}})/2]
}

sub dCog{ # displacement of cogs
	my ($a,$b)=@_;
	my ($cogA,$cogB)=(cog($a),cog($b));
	return [cog($a)->[0]-cog($b)->[0],cog($a)->[1]-cog($b)->[1]];
}

sub edgeReflect{
	my $s=shift;
	my $edge=atEdge($s);
	$$s{dy}=  abs ($$s{dy}) if ($edge=~/T/);	
	$$s{dy}= -abs ($$s{dy}) if ($edge=~/B/);
	$$s{dx}=  abs ($$s{dx}) if ($edge=~/L/);	
	$$s{dx}= -abs ($$s{dx}) if ($edge=~/R/);	
}

sub reflectXAngled{ #refkecting $b according to dCog between $b and $a
	my ($a,$b)=@_;
	$$b{dy}=(dCog($b,$a)->[1]/3);
	reflectX($b);
}

sub reflectX{
	my $s=shift;
	$$s{dx}=-$$s{dx};	
}

sub reflectY{
	my $s=shift;	
	$$s{dy}=-$$s{dy};	
}
sub atEdge{
	my $s=shift;
	my $edge="";	
	$edge.= "L" if ( $$s{x}<=$$s{minX});
	$edge.= "T" if ( $$s{y}<=$$s{minY});
	$edge.= "R" if ( $$s{x}>=$$s{maxX});
	$edge.= "B" if ( $$s{y}>=$$s{maxY});
	return $edge;
}

sub flipV{
	my $matrix=shift;	
	@$matrix=reverse @$matrix;  #$matrix=[reverse @$matrix] doesnt work...
}

sub flipH{
	my $matrix=shift;	
	$matrix->[$_]=[reverse @{$matrix->[$_]}] foreach(0..(scalar @{$matrix}-1));
}
sub transpose{
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

sub rotate{
	my ($matrix,$rotation)=@_;
	if ($rotation=~/^cw|90$/){
		transpose($matrix);
		flipV($matrix);
	}
	elsif ($rotation=~/^180/){
		flipV($matrix);
		flipH($matrix);
	}
	elsif ($rotation=~/^cxw|270$/){
		transpose($matrix);
		flipH($matrix);
	}
}



sub keyAction{
	  my $key = ReadKey(-1);                # -1 means non-blocking read
	  if ($key){
		my $OrdKey = ord($key);
		printAt (23,30,"key pressed=$OrdKey");
		$keyActions->{$OrdKey}->() if (exists $keyActions->{$OrdKey});
	  }  
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
  my @formats=map {lc $_} split / +/,$fmts;   
  my %colours=(black   =>30,red   =>31,green   =>32,yellow   =>33,blue   =>34,magenta   =>35,cyan  =>36,white   =>37,
               on_black=>40,on_red=>41,on_green=>42,on_yellow=>43,on_blue=>44,on_magenta=>4,on_cyan=>46,on_white=>47,
               reset=>0, bold=>1, italic=>3, underline=>4, strikethrough=>9,);
  return join "",map {defined $colours{$_}?"\033[$colours{$_}m":""} @formats;
}


