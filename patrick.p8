pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- patrick's cyberpunk challenge
-- by tobiasvl

modes={
  title_screen=1,
  play=2,
  win=3,
  game_over=4,
  tutorial=5,
  story=6,
}

function _init()
  mode=modes.title_screen
  menu_selection=1
  score=0
  run=0
  last_mouse=0
  cartdata("tobiasvl_patrick")
  poke(0x5f2d,1)
  title_y=50
  title_dir=true
  emulated=stat(102)!=0
  story_scroll=127
  kill=false
  mouse_pointer=16
end

menu={
  function() init_board() mode=modes.play end,
  function() init_board(true) page=1 mode=modes.tutorial end,
  function() init_board() story_scroll=127 mode=modes.story end,
  function() init_board(true,true) mode=modes.custom end
}

keys={
  [1]=function(x,y) return x>1 and x>patrick.x-1 and x-1 or x,y end,
  [2]=function(x,y) return x<7 and x<patrick.x+1 and x+1 or x,y end,
  [4]=function(x,y) return x,y>1 and y>patrick.y-1 and y-1 or y end,
  [8]=function(x,y) return x,y<4 and y<patrick.y+1 and y+1 or y end,
}

-- kill screen
kls=cls
function cls()
  if (not kill) kls()
end

function _update()
  if (run>127) kill=true
  local button=btnp()
  local mouse=stat(34)==1
  local temp_mouse=mouse
  mouse=mouse!=last_mouse and mouse or false
  last_mouse=temp_mouse
  if mode==modes.title_screen then
    menuitem(1)
    if (button==4) menu_selection=menu_selection==1 and #menu or menu_selection-1
    if (button==8) menu_selection=(menu_selection%#menu)+1
    if (button==0x10) menu[menu_selection]()
    if (button==0x20) kill=true --todo debug
  elseif mode==modes.play then
    menuitem(1,"title screen",function() mode=modes.title_screen end)
    if (button==0x20 and destroyed==0) init_board()
    if destroyed==27 then
      mode=modes.win
    elseif get_tile(patrick.x-1,patrick.y)==-1 and get_tile(patrick.x+1,patrick.y)==-1 and get_tile(patrick.x-1,patrick.y-1)==-1 and get_tile(patrick.x,patrick.y-1)==-1 and get_tile(patrick.x+1,patrick.y-1)==-1 and get_tile(patrick.x-1,patrick.y+1)==-1 and get_tile(patrick.x,patrick.y+1)==-1 and get_tile(patrick.x+1,patrick.y+1)==-1 then
      mode=modes.game_over
    end
    new_highlight={}
    new_highlight.x,new_highlight.y=highlight.x,highlight.y
    if button!=0 then
      for mask in all({1,2,4,8}) do
        if band(button,mask)!=0 then
          new_highlight.x,new_highlight.y=keys[mask](new_highlight.x,new_highlight.y)
        end
      end
    else
      local x,y=ceil(stat(32)/18),ceil((stat(33)-10)/18)
      new_highlight.x=(x==patrick.x-1 or x==patrick.x or x==patrick.x+1) and x or 0
      new_highlight.y=(y==patrick.y-1 or y==patrick.y or y==patrick.y+1) and y or 0
    end
    if get_tile(new_highlight.x,new_highlight.y)>=0 then
      highlight=new_highlight
    end
    if (button==0x10 or mouse) and not (highlight.x==patrick.x and highlight.y==patrick.y) then
      steps+=1
      mouse=false
      destroy_tile(patrick.x,patrick.y)
      patrick.x,patrick.y=highlight.x,highlight.y
      local tile=get_tile(highlight.x,highlight.y)
      if tile>0 then
        if tile==10 or tile==9 then
          destroy_tile(highlight.x-1,highlight.y-1)
          destroy_tile(highlight.x,highlight.y-1)
          destroy_tile(highlight.x+1,highlight.y-1)
        end
        if tile==8 or tile==9 then
          destroy_tile(highlight.x-1,highlight.y+1)
          destroy_tile(highlight.x,highlight.y+1)
          destroy_tile(highlight.x+1,highlight.y+1)
        end
        if tile==11 or tile==1 then
          destroy_tile(highlight.x-1,highlight.y-1)
          destroy_tile(highlight.x-1,highlight.y)
          destroy_tile(highlight.x-1,highlight.y+1)
        end
        if tile==12 or tile==1 then
          destroy_tile(highlight.x+1,highlight.y-1)
          destroy_tile(highlight.x+1,highlight.y)
          destroy_tile(highlight.x+1,highlight.y+1)
        end
        set_tile(highlight.x,highlight.y,0)
      end
    end
  elseif mode==modes.win then
    if btnp(4) or mouse then
      score+=60-steps
      run+=1
      if (score>high_score) dset(1,score) dset(2,run)
      init_board()
      mode=modes.play
      mouse=false
    end
  elseif mode==modes.game_over then
    if btnp(4) or mouse then
      score=max(0,score-60+steps)
      run+=1
      if (score>high_score) dset(1,score) dset(2,run)
      init_board()
      mode=modes.play
      mouse=false
    end
  elseif mode==modes.tutorial then
    menuitem(1,"title screen",function() mode=modes.title_screen end)
    if btnp(4) or mouse then
      page+=1
      if (page==6) init_board()
      if (page==12) mode=modes.play
    end
    if page==5 then
      for y=1,4 do
        for x=1,7 do
          if (not (patrick.x==x and patrick.y==y)) board[y][x]=-1
        end
      end
    elseif page==3 then
      local new_patrick={x=patrick.x,y=patrick.y}
      mask=flr(rnd(15))+1
      for i in all({band(mask,1),band(mask,2)}) do
        local should_break=false
        for j in all({band(mask,4),band(mask,8)}) do
          if (i!=0) new_patrick.x,new_patrick.y=keys[i](patrick.x,patrick.y)
          if (j!=0) new_patrick.x,new_patrick.y=keys[j](new_patrick.x,new_patrick.y)
          if get_tile(new_patrick.x,new_patrick.y)==0 then
            if (not (new_patrick.x==patrick.x and new_patrick.y==patrick.y)) destroy_tile(patrick.x,patrick.y) patrick=new_patrick should_break=true break
          end
        end
        if (should_break) break
      end
    end
  elseif mode==modes.story then
    menuitem(1,"title screen",function() mode=modes.title_screen end)
    if btn(2) then
      story_scroll-=1
    elseif btn(3) then
      story_scroll+=1
    elseif btnp(4) or btnp(5) then
      mode=modes.title_screen
    else
      if not kill then
        story_scroll-=0.2
      else
        if (story_scroll>-364) story_scroll-=1
      end
    end
  elseif mode==modes.custom then
    menuitem(1,"title screen",function() mode=modes.title_screen end)
    if mouse then
      local x,y=stat(32),stat(33)
      cell_x,cell_y=ceil(x/18),ceil((y-10)/18)
      if patrick.x==-1 and x>=0 and x<=15 and y>=94 and y<=110 then
        mouse_pointer=1
      elseif patrick.x==cell_x and patrick.y==cell_y then
        patrick={x=-1,y=-1}
        balls[1][2]=0
        mouse_pointer=1
      elseif balls[2][2]==0 and x>=16 and x<=24 and y>=94 and y<=102 then
        mouse_pointer=2
      elseif balls[3][2]==0 and x>=26 and x<=34 and y>=94 and y<=102 then
        mouse_pointer=3
      elseif balls[4][2]==0 and x>=36 and x<=44 and y>=94 and y<=102 then
        mouse_pointer=4
      elseif balls[5][2]==0 and x>=16 and x<=24 and y>=104 and y<=112 then
        mouse_pointer=5
      elseif balls[6][2]==0 and x>=26 and x<=34 and y>=104 and y<=112 then
        mouse_pointer=6
      elseif balls[7][2]==0 and x>=36 and x<=44 and y>=104 and y<=112 then
        mouse_pointer=7
      else
        local tile=get_tile(cell_x,cell_y)
        if tile!=-1 then
          if balls[mouse_pointer] then
            if mouse_pointer==1 then
              patrick.x,patrick.y=cell_x,cell_y
            else
              for i=2,7 do
                if tile==balls[i][1] then
                  board[cell_y][cell_x]=balls[mouse_pointer][1]
                  balls[i][2]=0
                  mouse_pointer=i
                  break
                end
              end
            end
            balls[mouse_pointer]={balls[mouse_pointer][1],cell_x+(7*(cell_y-1))}
            mouse_pointer=16
          end
          for i=2,7 do
            if tile==balls[i][1] then
              board[cell_y][cell_x]=0
              balls[i][2]=0
              mouse_pointer=i
              break
            end
          end
        else
          mouse_pointer=16
        end
      end
    end
  end
end

function _draw()
  if mode==modes.title_screen then
    cls()
    center("patrick's",11)
    center("cyberpunk",3)
    center("challenge",8)
    if (title_dir) title_y+=0.5 else title_y-=0.5
    if (title_y==128 or title_y==50) title_dir=not title_dir
    line(0,title_y,127,title_y,14)
    line(0,title_y+6,127,title_y+6,14)
    line(0,title_y+16,127,title_y+16,14)
    line(0,title_y+28,127,title_y+28,14)
    line(0,title_y+46,127,title_y+46,14)
    line(64,title_y,64,127,14)
    line(50,title_y,40,127,14)
    line(36,title_y,10,127,14)
    line(22,title_y,-30,127,14)
    line(8,title_y,-80,127,14)
    line(120,title_y,127+80,127,14)
    line(106,title_y,127+30,127,14)
    line(92,title_y,127-10,127,14)
    line(78,title_y,127-40,127,14)
    cursor(45,30)
    print(menu_selection==1 and ">play_" or "play")
    print(menu_selection==2 and ">tutorial_" or "tutorial")
    print(menu_selection==3 and ">story_" or "story")
    print(menu_selection==4 and ">custom_" or "custom")
    high_score=dget(1)
    high_run=dget(2)
    cursor(0,100)
    center("high score: "..high_score,7)
    center("(over "..high_run.." levels)",7)
  elseif mode==modes.tutorial then
    cls()
    print("z: next",128-(7*4),0,7)
    local offset=10
    for y=1,4 do
      for x=1,7 do
        local tile=get_tile(x,y)
        if tile>=0 then
          rect(18*(x-1),offset+(18*(y-1)),18*(x),offset+(18*(y)),14)
          local bg=2
          if (page==2 and (x==patrick.x-1 or x==patrick.x or x==patrick.x+1) and (y==patrick.y-1 or y==patrick.y or y==patrick.y+1)) bg=5
          if (patrick.x==x and patrick.y==y) bg=6
          rectfill(18*(x-1)+1,offset+(18*(y-1))+1,18*(x)-1,offset+(18*(y))-1,bg)
          if (tile>0) circfill(18*(x-1)+9,offset+(18*(y-1))+9,4,tile)
        end
      end
    end
    palt(0,false)
    palt(6,true)
    spr(1,(18*(patrick.x-1))+2,offset+(18*(patrick.y-1))+2,2,2)
    palt()
    rectfill(0,83,127,127,0)
    cursor(0,88)
    color(11)
    if page==1 then
      print("the object of the game is to")
      print("remove all 28 squares.")
    elseif page==2 then
      print("patrick can move to any square")
      print("that is adjacent to where he is.")
      print("(even diagonally!)")
    elseif page==3 then
      print("each time patrick moves, the")
      print("square he was on will disappear.")
    elseif page==4 then
      oh_no()
      color(11)
      cursor(0,88)
      print("you will lose when patrick can")
      print("no longer move to any remaining")
      print("squares.")
    elseif page==5 then
      all_right()
      color(11)
      cursor(0,88)
      print("if you make all the squares")
      print("disappear, you win the level.\n")
      print("either way, a new level will")
      print("automatically be generated.")
    elseif page==6 then
      print("moving patrick to a")
      print("colored ball will")
      print("make the correspon-")
      print("ding squares (see")
      print("legend) disappear.")
      print_legend()
    elseif page==7 then
      cursor(36,88)
      print("for each level you win")
      print("you get 60 points minus")
      print("the number of squares")
      print("you landed on.")
      print("level "..run+1,0,88,7)
      print("score "..score,0,94,7)
      print("win  +"..60-steps,0,100,11)
      print("lose -"..60+steps,0,106,5)
    elseif page==8 then
      cursor(36,88)
      print("for each level you lose,")
      print("you get 60 points plus")
      print("the number of squares")
      print("you landed on deducted")
      print("from your score.")
      print("level "..run+1,0,88,7)
      print("score "..score,0,94,7)
      print("win  +"..60-steps,0,100,5)
      print("lose -"..60+steps,0,106,8)
    elseif page==9 then
      cursor(0,86)
      color(11)
      print("each level has a seven-numbered")
      print("code, which you can write down")
      print("to play later, or give to a")
      print("friend. use the \"custom\" mode")
      print("to input codes and play a single")
      print("level.")
    elseif page==10 then
      cursor(0,86)
      print("each number says what square a")
      print("ball occupies, 1-28 (or 0 for")
      print("none). duplicate numbers are")
      print("overridden from left to right.")
      print("the white number is patrick and")
      print("can't be 0 or overridden.")
    elseif page==11 then
      cursor(0,86)
      print("it is unknown at this time")
      print("whether it is possible to have")
      print("or create an unsolvable level.")
      print("you can skip a level without")
      print("penalty if you have not made any")
      print("moves and think it's impossible.")
    end
    if page==9 or page==10 or page==11 then
      print_code()
    end
  elseif mode==modes.play or mode==modes.win or mode==modes.game_over then
    cls()
    print_code()
    if (destroyed==0) print("x: skip",128-(7*4),0,7)
    local offset=10
    for y=1,4 do
      for x=1,7 do
        local tile=get_tile(x,y)
        if tile>=0 then
          rect(18*(x-1),offset+(18*(y-1)),18*(x),offset+(18*(y)),14)
          local bg=2
          if (not kill and (x==patrick.x-1 or x==patrick.x or x==patrick.x+1) and (y==patrick.y-1 or y==patrick.y or y==patrick.y+1)) bg=5
          if (patrick.x==x and patrick.y==y) bg=0
          if (highlight.x==x and highlight.y==y) bg=6
          local highlighted_tile=get_tile(highlight.x,highlight.y)
          if not kill and highlighted_tile>0 then
            if highlighted_tile==10 or highlighted_tile==9 then
              if (y==highlight.y-1 and (x==highlight.x-1 or x==highlight.x or x==highlight.x+1)) bg=0
            end
            if highlighted_tile==8 or highlighted_tile==9 then
              if (y==highlight.y+1 and (x==highlight.x-1 or x==highlight.x or x==highlight.x+1)) bg=0
            end
            if highlighted_tile==11 or highlighted_tile==1 then
              if (x==highlight.x-1 and (y==highlight.y-1 or y==highlight.y or y==highlight.y+1)) bg=0
            end
            if highlighted_tile==12 or highlighted_tile==1 then
              if (x==highlight.x+1 and (y==highlight.y-1 or y==highlight.y or y==highlight.y+1)) bg=0
            end
          end
          rectfill(18*(x-1)+1,offset+(18*(y-1))+1,18*(x)-1,offset+(18*(y))-1,bg)
          if (tile>0) circfill(18*(x-1)+9,offset+(18*(y-1))+9,4,tile)
        end
      end
    end
    palt(0,false)
    palt(6,true)
    local sprite=1
    if kill then
      local foo=run%balls[1][2]
      if (foo==3) sprite=3
      if (foo==5) sprite=39
      if (foo==7) sprite=41
    end
    spr(sprite,(18*(patrick.x-1))+2,offset+(18*(patrick.y-1))+2,2,2)
    palt()
    print("level"..(kill and "-" or " ")..run+1,0,88,7)
    print("score "..score,0,94,7)
    print("win  +"..60-steps,0,100,5)
    print("lose -"..60+steps,0,106,5)
    print_legend()
    if (not emulated) spr(16,stat(32),stat(33))
  end
  if mode==modes.win then
    print("z: next",128-(7*4),0,7)
    print("score "..score,0,94,5)
    print("win  +"..60-steps,0,100,11)
    print("score="..score+(60-steps),0,114,7)
    all_right()
  elseif mode==modes.game_over then
    print("z: next",128-(7*4),0,7)
    print("score "..score,0,94,5)
    print("lose -"..60+steps,0,106,8)
    print("score="..max(0,score-(60+steps)),0,114,7)
    oh_no()
  elseif mode==modes.story then
    if (kill) cls(5) else cls()
    story={
      "it is the year 2077.",
      "",
      "the evil ernie york, former",
      "electronic store owner and",
      "cryogenics innovator, now",
      "mutated multibillionaire ceo of",
      "the sinister zebra corporation,",
      "rules fun land with his army of",
      "advanced robots - beings dis-",
      "similar to humans - known as",
      "tomb bots",
      "",
      "",
      "",
      "",
      "",
      "the immortal spirit of the",
      "leprechaun patrick magee - now",
      "clad in sunglasses and a black",
      "coat - is the last vestige of",
      "the jackie gleason appreciation",
      "society, an ancient underground",
      "rebel alliance.",
      "",
      "",
      "",
      "",
      "",
      "now patrick must traverse and",
      "dismantle the mazes of szc's",
      "virtual reality system to shut",
      "down the tomb bot factories.",
      "hindering his quest are digital",
      "versions of the szc's neon",
      "\"shine 'n glow\" energy balls;",
      "but perhaps they can help too?",
      "",
      "",
      "",
      "",
      "",
      "are you ready for the challenge?",
    }
    local scroll_offset=0
    if kill then
      cursor(0,story_scroll)
    else
      spr(39,56,12*6+story_scroll,2,2)
      palt(0,false)
      palt(6,true)
      spr(story_scroll<-50 and 1 or 3,56,24*6+story_scroll,2,2)
      palt()
      local ball_x=40
      for ball in all(balls) do
        if ball[1]!=7 then
          circfill(ball_x,38*6+story_scroll,4,ball[1])
          ball_x+=10
        end
      end
      if (story_scroll<-300) local str="press z" print(str,64-(#str*2),64,7)
    end
    for str in all(story) do
      if (scroll_offset==6*10) color(8) else color(7)
      if not kill then
        print(str,64-(#str*2),story_scroll+scroll_offset)
        local x,y=flr(rnd(127)),flr(rnd(127))
        line(x,y,x-3,y-3,7)
      else
        if (story_scroll<-300) cls=kls
        if (str!="") center(str)
        palt(0,false)
        palt(6,true)
        spr(41,story_scroll+427,40,2,2)
        spr(43,story_scroll+427,40+16,2,1)
        spr(story_scroll%12!=0 and 59 or 45,story_scroll+427,40+24)
        spr(story_scroll%10!=0 and 60 or 61,story_scroll+427+8,40+24)
        palt()
        if (story_scroll==-364) spr(36,54,25,3,2,true) print("where\nam i?",56,26,0)
      end
      scroll_offset+=6
    end
  elseif mode==modes.custom then
    cls()
    print_code()
    print_legend()
    local offset=10
    for y=1,4 do
      for x=1,7 do
        local tile=get_tile(x,y)
        if tile>=0 then
          rect(18*(x-1),offset+(18*(y-1)),18*(x),offset+(18*(y)),14)
          local bg=2
          --if (patrick.x==x and patrick.y==y) bg=6
          rectfill(18*(x-1)+1,offset+(18*(y-1))+1,18*(x)-1,offset+(18*(y))-1,bg)
          if (tile>0) circfill(18*(x-1)+9,offset+(18*(y-1))+9,4,tile)
        end
      end
    end
    palt(0,false)
    palt(6,true)
    if mouse_pointer==1 then
      spr(1,stat(32),stat(33),2,2)
    elseif patrick.x==-1 then
      spr(1,0,94,2,2)
    else
      spr(1,(18*(patrick.x-1))+2,offset+(18*(patrick.y-1))+2,2,2)
    end
    palt()
    local x,y=20,98
    for i=2,7 do
      if mouse_pointer==i then
        circfill(stat(32)+4,stat(33)+4,4,balls[i][1])
      elseif balls[i][2]==0 then
        circfill(x,y,4,balls[i][1])
      end
      x+=10
      if (x==50) x,y=20,108
    end
    if (not emulated) spr(16,stat(32),stat(33))
  end
  if page==12 and run==0 then
    print("good\nluck",50,94,11)
  elseif kill and run==130 then
    print(" kill\nscreen",44,94,8)
  end
end

function center(str,c)
  local x=peek(0x5f26)
  poke(0x5f26,64-(#str*2))
  c=c or 7
  color(c)
  print(str)
  poke(0x5f26,x)
end

function all_right()
  local offset,flip=16,false
  if patrick.x==1 then
    offset=19
  elseif patrick.x==7 then
    offset,flip=14,true
  end
  spr(36,(18*(patrick.x-2))+offset,10+(18*(patrick.y-2))+9,3,2,flip)
  print(" all\nright",(18*(patrick.x-2))+2+offset,10+(18*(patrick.y-2))+10,0)
end

function oh_no()
  local offset,flip=9,false
  if (patrick.x==1) offset,flip=32,true
  spr(34,(18*(patrick.x-2))+offset,10+(18*(patrick.y-2))+9,2,2,flip)
  print("oh\nno",(18*(patrick.x-2))+4+offset,10+(18*(patrick.y-2))+10,0)
end

function print_code()
  local x=0
  print(balls[1][2],x,0,balls[1][1])
  x+=#(tostr(balls[1][2]).." ")*4
  for i=7,2,-1 do
    print(balls[i][2].." ",x,0,balls[i][1])
    x+=#tostr(balls[i][2].." ")*4
  end
end

function print_legend()
  print("legend",86,88,6)
  spr(5,86,94,2,2)
  spr(7,86,108,2,2)
  spr(11,100,94,2,2)
  spr(9,100,108,2,2)
  spr(32,114,94,2,2)
  spr(13,114,108,2,2)
end

function init_board(skip_balls,skip_patrick)
  if not skip_balls then
    balls={
      {7,flr(rnd(28))+1},
      {9,flr(rnd(29))},
      {8,flr(rnd(29))},
      {11,flr(rnd(29))},
      {1,flr(rnd(29))},
      {12,flr(rnd(29))},
      {10,flr(rnd(29))}
    }
  else
    balls={
      {7,0},
      {9,0},
      {8,0},
      {11,0},
      {1,0},
      {12,0},
      {10,0}
    }
    if (not skip_patrick) balls={{7,flr(rnd(28))+1}} else patrick={x=-1,y=-1}
  end
  steps=0
  destroyed=0
  board={}
  highlight={}
  local location=0
  for y=1,4 do
    add(board,{})
    for x=1,7 do
      location+=1
      add(board[y],0)
      for ball in all(balls) do
        if (location==ball[2]) then
          if (ball[1]==7) patrick={x=x,y=y} else set_tile(x,y,ball[1])
          break
        end
      end
    end
  end
  if (not skip_patrick) highlight.x,highlight.y=patrick.x,patrick.y
end

function get_tile(x,y)
  if x>=1 and x<=7 and y>=1 and y<=4 then
    return board[y][x]
  else
    return -1
  end
end

function set_tile(x,y,val)
  if x>=1 and x<=7 and y>=1 and y<=4 and board[y][x]!=val then
    board[y][x]=val
    return true
  else
    return false
  end
end

function destroy_tile(x,y)
  if (set_tile(x,y,-1)) destroyed+=1
end

__gfx__
0000000066666555555666666666633333366666eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee00000000000
0000000066555555555555666633333333333366e000e000e000e000e000e222e222e000e222e222e000e000e222e222e222e000e000e222e000e00000000000
0070070066644444444446666664444444444666e000e000e000e000e000e222e222e000e222e222e000e000e222e222e222e000e000e222e000e00000000000
00077000664aaaaaaaaa44666644aaaaaaaaa466e000e000e000e000e000e222e222e000e222e222e000e000e222e222e222e000e000e222e000e00000000000
00077000660000000000006666aaccaaaaccaa66eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee00000000000
0070070066aa00a0aa00aa6666aac0a0aac0aa66e222eaaae222e000e000ebbbe222e000e222eccce000e000e222e888e222e000e000e111e000e00000000000
0000000066aaaaa0aaaaaa6666aaaaa0aaaaaa66e222eaaae222e000e000ebbbe222e000e222eccce000e000e222e888e222e000e000e111e000e00000000000
0000000066aaaaa00aaaaa6666aaaaa00aaaaa66e222eaaae222e000e000ebbbe222e000e222eccce000e000e222e888e222e000e000e111e000e00000000000
30000000666aaaaaa88aa666666aa8aaaa8aa666eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee00000000000
330000006666aaaaaaaa66666666aa8888aa6666e222e222e222e000e000e222e222e000e222e222e000e000e000e000e000e000e000e222e000e00000000000
3330000066666655556666666666663333666666e222e222e222e000e000e222e222e000e222e222e000e000e000e000e000e000e000e222e000e00000000000
3333000066555555555555666633333333333366e222e222e222e000e000e222e222e000e222e222e000e000e000e000e000e000e000e222e000e00000000000
3333300065565555555565566336333333336336eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee00000000000
33300000655655555555655663363333333363360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000000666655666655666666663366663366660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666655666655666666663366663366660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeee000077777777777777007777777777777777777777000007777777700006666666676666666666667777777766666aa67770000000000000000
e000e000e000e0007777777777777777777777777777777777777777000777777777700066666667776666666666777777777766666667770000000000000000
e000e000e000e0007777777777777777777777777777777777777777007788777788770066666677777666666667777777777776666667770000000000000000
e000e000e000e0007777777777777777777777777777777777777777007788737788770066666777877766666677777787777777666688880000000000000000
eeeeeeeeeeeee0007777777777777777777777777777777777777777007777333777770066667777777776666677777777777777666688880000000000000000
e222e999e222e0007777777777777777777777777777777777777777007777737777770066677777877777666677677777777677666688880000000000000000
e222e999e222e0007777777777777777777777777777777777777777007777777777770066777777777777766677677787777677666666660000000000000000
e222e999e222e00077777777777777777777777777777777777777770007788888877000660000000000000666aa6777777776aa666666660000000000000000
eeeeeeeeeeeee00077777777777777777777777777777777777777770000777777770000660aaaaaaaaaaa0666aa6777777776aa777776aa0000000000000000
e000e000e000e0007777777777777777777777777777777777777777000008811880000066a00000000000a66666677787777666877776660000000000000000
e000e000e000e0007777777777777777777777777777777777777777000088811888000066aa000aaa000aa66666677777777666777776660000000000000000
e000e000e000e00077777777777777777777777777777777777777770007788118877000666a000aaa000a666666677777777666778888660000000000000000
eeeeeeeeeeeee00007777777777777700777777777777777777777700007788118877000666aaaa00aaaaa666666677766777666668888660000000000000000
000000000000000000000000007770000000000000000000000777000000111111110000666aaaaaaaaaaa666666677766777666666666660000000000000000
0000000000000000000000000007700000000000000000000007700000008800008800006666aaa888aaa6666666888866888866666666660000000000000000
000000000000000000000000000077000000000000000000007700000008880000888000666666aaaaaa66666666888866888866666666660000000000000000
