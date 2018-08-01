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
  custom=7,
  custom_play=8,
  win_custom=9,
  game_over_custom=10,
}

function _init()
  mode=modes.title_screen
  menu_selection=1
  score=0
  run=0
  last_mouse=0
  cartdata("tobiasvl_patrick")
  poke(0x5f2d,1)
  title_dir=true
  emulated=stat(102)!=0
  keyboard=stat(102)!=0 and stat(102)!="www.lexaloffle.com" and stat(102)!="www.playpico.com"
  buttons={o=keyboard and "z" or "🅾️",x=keyboard and "x" or "❎"}
  story_scroll=127
  kill=false
  mouse_pointer=0
  music(0)
  title_lines={
    {64,90,64,127,14},
    {50,90,40,127,14},
    {36,90,10,127,14},
    {22,90,-30,127,14},
    {8,90,-80.5,127,14},
    {120,90,127+65,127,14},
    {106,90,127+30,127,14},
    {92,90,127-10.5,127,14},
    {78,90,127-40.5,127,14},
  }
end

menu={
  {function() init_board() mode=modes.play music(-1) end, "play"},
  {function() init_board(true) page=1 mode=modes.tutorial music(-1) end, "tutorial"},
  {function() init_board() story_scroll=127 mode=modes.story end, "story"},
  {function() init_board(true,true) mode=modes.custom music(-1) end, "custom"}
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
    if (button==0x10) menu[menu_selection][1]()
    if (button==0x20) kill=true --todo debug
  elseif mode==modes.play or mode==modes.custom_play then
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
    if (mode==modes.play and button==0x20 and destroyed==0) init_board()
    if destroyed==27 then
      sfx(25)
      mode=mode==modes.play and modes.win or modes.win_custom
    elseif get_tile(patrick.x-1,patrick.y)==-1 and get_tile(patrick.x+1,patrick.y)==-1 and get_tile(patrick.x-1,patrick.y-1)==-1 and get_tile(patrick.x,patrick.y-1)==-1 and get_tile(patrick.x+1,patrick.y-1)==-1 and get_tile(patrick.x-1,patrick.y+1)==-1 and get_tile(patrick.x,patrick.y+1)==-1 and get_tile(patrick.x+1,patrick.y+1)==-1 then
      sfx(8)
      mode=mode==modes.play and modes.game_over or modes.game_over_custom
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
        sfx(33)
        if tile==7 or tile==2 then
          destroy_tile(highlight.x-1,highlight.y-1)
          destroy_tile(highlight.x,highlight.y-1)
          destroy_tile(highlight.x+1,highlight.y-1)
        end
        if tile==3 or tile==2 then
          destroy_tile(highlight.x-1,highlight.y+1)
          destroy_tile(highlight.x,highlight.y+1)
          destroy_tile(highlight.x+1,highlight.y+1)
        end
        if tile==4 or tile==5 then
          destroy_tile(highlight.x-1,highlight.y-1)
          destroy_tile(highlight.x-1,highlight.y)
          destroy_tile(highlight.x-1,highlight.y+1)
        end
        if tile==6 or tile==5 then
          destroy_tile(highlight.x+1,highlight.y-1)
          destroy_tile(highlight.x+1,highlight.y)
          destroy_tile(highlight.x+1,highlight.y+1)
        end
        set_tile(highlight.x,highlight.y,0)
      elseif destroyed!=27 then
        sfx(60)
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
  elseif mode==modes.win_custom or mode==modes.game_over_custom then
    if btnp(4) or mouse then
      board=backup.board
      patrick=backup.patrick
      balls=backup.balls
      mode=modes.custom
      mouse=false
    end
  elseif mode==modes.tutorial then
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
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
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
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
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
    if patrick.x>0 and btnp(4) then
      highlight.x,highlight.y=patrick.x,patrick.y
      mode=modes.custom_play
      steps=0
      destroyed=0
      backup={}
      backup.board,backup.balls,backup.patrick={},{},{}
      backup.patrick.x,backup.patrick.y=patrick.x,patrick.y
      for y=1,4 do
        backup.board[y]={}
        for x=1,7 do
          backup.board[y][x]=board[y][x]
        end
      end
      for i=1,7 do
        backup.balls[i]={}
        backup.balls[i].id=balls[i].id
        backup.balls[i].color=balls[i].color
        backup.balls[i].pos=balls[i].pos
      end
    end
    if mouse then
      local x,y=stat(32),stat(33)
      cell_x,cell_y=ceil(x/18),ceil((y-10)/18)
      if mouse_pointer!=0 and get_tile(cell_x,cell_y)==-1 then
        mouse_pointer=0
      elseif patrick.x==-1 and x>=0 and x<=15 and y>=94 and y<=110 then
        mouse_pointer=1
      elseif patrick.x==cell_x and patrick.y==cell_y then
        patrick={x=-1,y=-1}
        balls[1].pos=0
        mouse_pointer=1
      elseif balls[2].pos==0 and x>=16 and x<=24 and y>=94 and y<=102 then
        mouse_pointer=2
      elseif balls[3].pos==0 and x>=26 and x<=34 and y>=94 and y<=102 then
        mouse_pointer=3
      elseif balls[4].pos==0 and x>=36 and x<=44 and y>=94 and y<=102 then
        mouse_pointer=4
      elseif balls[5].pos==0 and x>=16 and x<=24 and y>=104 and y<=112 then
        mouse_pointer=5
      elseif balls[6].pos==0 and x>=26 and x<=34 and y>=104 and y<=112 then
        mouse_pointer=6
      elseif balls[7].pos==0 and x>=36 and x<=44 and y>=104 and y<=112 then
        mouse_pointer=7
      elseif get_tile(cell_x,cell_y)==0 then
        if mouse_pointer==1 then
          patrick.x,patrick.y=cell_x,cell_y
        elseif mouse_pointer>0 then
          set_tile(cell_x,cell_y,balls[mouse_pointer].id)
        end
        balls[mouse_pointer].pos=cell_x+(7*(cell_y-1))
        mouse_pointer=0
      elseif get_tile(cell_x,cell_y)>0 then
        local pick_up=get_tile(cell_x,cell_y)
        set_tile(cell_x,cell_y,0)
        balls[pick_up].pos=0
        if (pick_up==1) patrick.x,patrick.y=-1,-1
        if mouse_pointer==1 then
          patrick.x,patrick.y=cell_x,cell_y
          balls[mouse_pointer].pos=cell_x+(7*(cell_y-1))
        elseif mouse_pointer>0 then
          set_tile(cell_x,cell_y,balls[mouse_pointer].id)
          balls[mouse_pointer].pos=cell_x+(7*(cell_y-1))
        end
        mouse_pointer=pick_up
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
    title_y=90

    line(0,85,127,85,1)
    line(0,86,127,86,2)
    line(0,87,127,87,13)
    line(0,88,127,88,9)
    line(0,89,127,89,10)
    line(0,90,127,90,14)
    line(0,title_y+6,127,title_y+6,14)
    line(0,title_y+16,127,title_y+16,14)
    line(0,title_y+28,127,title_y+28,14)
    line(0,title_y+46,127,title_y+46,14)
    for i=1,#title_lines do
      line(title_lines[i][1],title_lines[i][2],title_lines[i][3],title_lines[i][4],14)
      title_lines[i][1]-=0.5
      title_lines[i][3]-=1
      if (title_lines[i][1]<0) title_lines[i]={135,90,127+80,127,14}
    end
    cursor(47,30)
    for i=1,4 do
      color(menu_selection==i and 10 or 14)
      if (menu_selection==i) then
        color(10)
        print(">"..menu[i][2].."_")
      else
        color(14)
        print(menu[i][2])
      end
    end
    if (flr(time())%2==0) center("\npress "..buttons.o,6)
    color()
    high_score=dget(1)
    high_run=dget(2)
    cursor(0,72)
    center("high score: "..high_score,7)
    center("(run: "..high_run.." levels)",7)
    cursor(0,107)
    center("by",5)
    center("tobiasvl",5)
  elseif mode==modes.tutorial then
    cls()
    local s=buttons.o..": next"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
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
          if (tile>0) circfill(18*(x-1)+9,offset+(18*(y-1))+9,4,balls[tile].color)
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
      cursor(0,86)
      print("patrick can move to any square")
      print("that is adjacent to where he is.")
      print("(even diagonally!)")
      print("                 ⬆️")
      print("select square: ⬅️⬇️➡️  move: "..buttons.o)
      print("                  (or mouse)")
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
  elseif mode==modes.play or mode==modes.win or mode==modes.game_over or mode==modes.custom_play then
    cls()
    print_code()
    if (destroyed==0 and mode==modes.play) local s=buttons.x..": skip" print(s,128-((keyboard and 7 or 8)*4),0,7)
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
            if highlighted_tile==7 or highlighted_tile==2 then
              if (y==highlight.y-1 and (x==highlight.x-1 or x==highlight.x or x==highlight.x+1)) bg=0
            end
            if highlighted_tile==3 or highlighted_tile==2 then
              if (y==highlight.y+1 and (x==highlight.x-1 or x==highlight.x or x==highlight.x+1)) bg=0
            end
            if highlighted_tile==4 or highlighted_tile==5 then
              if (x==highlight.x-1 and (y==highlight.y-1 or y==highlight.y or y==highlight.y+1)) bg=0
            end
            if highlighted_tile==6 or highlighted_tile==5 then
              if (x==highlight.x+1 and (y==highlight.y-1 or y==highlight.y or y==highlight.y+1)) bg=0
            end
          end
          rectfill(18*(x-1)+1,offset+(18*(y-1))+1,18*(x)-1,offset+(18*(y))-1,bg)
          if (tile>0) circfill(18*(x-1)+9,offset+(18*(y-1))+9,4,balls[tile].color)
        end
      end
    end
    palt(0,false)
    palt(6,true)
    local sprite=1
    if kill then
      local foo=run%balls[1].pos
      if (foo==3) sprite=3
      if (foo==5) sprite=39
      if (foo==7) sprite=41
      if (foo==9) sprite=46
      if (foo==13) sprite=64
      if (foo==15) sprite=66
    end
    spr(sprite,(18*(patrick.x-1))+2,offset+(18*(patrick.y-1))+2,2,2)
    palt()
    if mode!=modes.custom_play then
      print("level"..(kill and "-" or " ")..run+1,0,88,7)
      print("score "..score,0,94,7)
    end
    print("win  +"..60-steps,0,100,5)
    print("lose -"..60+steps,0,106,5)
    print_legend()
    if (not emulated) spr(16,stat(32),stat(33))
  end
  if mode==modes.win then
    local s=buttons.o..": next"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("score "..score,0,94,5)
    print("win  +"..60-steps,0,100,11)
    print("score="..score+(60-steps),0,114,7)
    all_right()
  elseif mode==modes.game_over then
    local s=buttons.o..": next"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("score "..score,0,94,5)
    print("lose -"..60+steps,0,106,8)
    print("score="..max(0,score-(60+steps)),0,114,7)
    oh_no()
  elseif mode==modes.win_custom then
    local s=buttons.o..": edit"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("score "..60-steps,0,100,11)
    all_right()
  elseif mode==modes.game_over_custom then
    local s=buttons.o..": edit"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("lose -"..60+steps,0,106,8)
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
        if ball.id!=1 then -- todo ball.id!=1
          circfill(ball_x,38*6+story_scroll,4,ball.color)
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
    if (patrick.x>0) local s=buttons.o..": play" print(s,128-((keyboard and 7 or 8)*4),0,7)
    print_legend()
    local offset=10
    for y=1,4 do
      for x=1,7 do
        local tile=get_tile(x,y)
        if tile>=0 then
          rect(18*(x-1),offset+(18*(y-1)),18*(x),offset+(18*(y)),14)
          local bg=2
          rectfill(18*(x-1)+1,offset+(18*(y-1))+1,18*(x)-1,offset+(18*(y))-1,bg)
          if (tile>0) circfill(18*(x-1)+9,offset+(18*(y-1))+9,4,balls[tile].color)
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
        circfill(stat(32)+4,stat(33)+4,4,balls[i].color)
      elseif balls[i].pos==0 then
        circfill(x,y,4,balls[i].color)
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
  print(balls[1].pos,x,0,balls[1].color)
  x+=#(tostr(balls[1].pos).." ")*4
  for i=7,2,-1 do
    print(balls[i].pos.." ",x,0,balls[i].color)
    x+=#tostr(balls[i].pos.." ")*4
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
  balls={
    {id=1,color=7,pos=0},
    {id=2,color=9,pos=0},
    {id=3,color=8,pos=0},
    {id=4,color=11,pos=0},
    {id=5,color=1,pos=0},
    {id=6,color=12,pos=0},
    {id=7,color=10,pos=0}
  }
  if not skip_balls then
    for ball in all(balls) do
      ball.pos=flr(rnd(28))+1
    end
  end
  if (not skip_patrick) balls[1].pos=flr(rnd(28))+1 else patrick={x=-1,y=-1}
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
        if (location==ball.pos) then
          if (ball.id==1) patrick={x=x,y=y} else set_tile(x,y,ball.id)
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
eeeeeeeeeeeee000077777777777777007777777777777777777777000007777777700006666666676666666666667777777766666aa67776666366666636666
e000e000e000e0007777777777777777777777777777777777777777000777777777700066666667776666666666777777777766666667776666366666636666
e000e000e000e0007777777777777777777777777777777777777777007788777788770066666677777666666667777777777776666667776663333333333666
e000e000e000e0007777777777777777777777777777777777777777007788737788770066666777877766666677777787777777666688886633333333333366
eeeeeeeeeeeee0007777777777777777777777777777777777777777007777333777770066667777777776666677777777777777666688886633003333003366
e222e999e222e0007777777777777777777777777777777777777777007777737777770066677777877777666677677777777677666688886633003333003366
e222e999e222e0007777777777777777777777777777777777777777007777777777770066777777777777766677677787777677666666666633c333333c3366
e222e999e222e00077777777777777777777777777777777777777770007788888877000660000000000000666aa6777777776aa666666666633c338833c3366
eeeeeeeeeeeee00077777777777777777777777777777777777777770000777777770000660aaaaaaaaaaa0666aa6777777776aa777776aa6663338338333666
e000e000e000e0007777777777777777777777777777777777777777000008811880000066a00000000000a66666677787777666877776666666333333336666
e000e000e000e0007777777777777777777777777777777777777777000088811888000066aa000aaa000aa66666677777777666777776666666663333666666
e000e000e000e00077777777777777777777777777777777777777770007788118877000666a000aaa000a666666677777777666778888666633333333333366
eeeeeeeeeeeee00007777777777777700777777777777777777777700007788118877000666aaaa00aaaaa666666677766777666668888666336333333336336
000000000000000000000000007770000000000000000000000777000000111111110000666aaaaaaaaaaa666666677766777666666666666336333333336336
0000000000000000000000000007700000000000000000000007700000008800008800006666aaa888aaa6666666888866888866666666666666336666336666
000000000000000000000000000077000000000000000000007700000008880000888000666666aaaaaa66666666888866888866666666666666336666336666
66666666666666666666668888666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6866888888886666666668c00c866666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8668888888888666666668cccc866666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86880008800088666666668888666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8688a0a88a0a88666666666886666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86880008800088666666668888666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86888888888888666668888888888666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86888000000888666888888888888886000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
886888cccc8886668888888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888688c88c8866668888888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888888c88c8888668888888008888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888866888880000888886000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6888888888888886668888a00a888866000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6688888888888886666888a88a888666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6688888668888866666886a66a688666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66888866668888666688886666888866000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0101000018030180301f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f030
010100000000000000000001b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b250
010100000000000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330
010100000f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f030
010100001b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b2501b25018240
010100000033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330
010200000f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f030
010200001824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240
010200000033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330003300033000330
010100001824013230132301323013230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240
010100001824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182400000000000000000000000000000000000000000000001324013240
010100001324013240132401324013240132401324013240132401324013240132401324013240132401324013240132401324000000000000000000000000000000000000000000000000000000000000000000
010200000000000000000000000000000000000000000000000000000000000000000000000000000001824018240182401824018240182401824018240182401824018240182401824018240182401824018240
010100001824018240182401824018240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b2501b250
010200001b2500c2400c2400c2400c2400c2400c2400c240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200001823018230182301823018230182301823018230182301823018230182301823018230182301823018230182301823018230182301823018230182301823018230182301823018230182301823018230
010100001823013240132401324013240132401324013240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000182301823018230182301823018230182301823018230182301823018230182301823018230
010200001823000000000000000000000000000000000000000000000000000000000000000000000000000013240132401324013240132401324013240132401324013240132401324013240132401324013240
010100001324013240132401324013240132401324013240132401324013240132401324013240132401324013240132401324013240132401324013240132401324013240132401324013240132401324013240
010100001324018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240182401824018240
010100000f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f0300f03000000000000000000000000000000000000000001d030
010100001824018240182400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000033000330003300033000330003300033000330003300033000330003300033000330003300033000330000000000000000000000000000000000000000000000000000000000000000000000000000
010100001d0301a030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030
01010000000000a2401a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a2501a250
01010000000000a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a330
010400001603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030
010400001a2501a2501a2501a2501a2501a2501a2501a250162301623016230162301623016230162301623016230162301623016230162301623016230162301623016230162301623016230162301623011230
010400000a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a330
010100001603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030
010100001123011230112301123011230112301123011230112301123011230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a330
010200001603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030
010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000162301623016230162301623016230162301623016230162301623016230162301623016230
010200000a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a330
010100001623016230162301623016230162301623016230162301623016230162301623000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011230
010100001123011230112301123011230112301123011230112301123011230112301123011230112300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000162401624016240162401624016240162401624016240162401624016240162401624016240
010100001624016240162401624016240162401624000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000000001a2501a2501a2501a2501a2501a2501a2501a2500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240
010100001624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624011230
010200001123011230112300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000016230162301623016230162301623016230162301623016230162301623016230162301623016230162301623016230162301623016230162301623016230162301623016230162301623016230
010100001623016230162301623016230162300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240
010100001124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124011240112401124016240
010100001624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240
010100001603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603016030160301603000000000000000000000000000000000000
010100001624016240162401624016240162401624000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007240
010100000a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300a3300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010000000001a0301a0301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030
010100000724007240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240162401624016240
010100000000007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330
010400001303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030
010400001624016240162401624016240162401624016240132401324013240132401324013240132401324013240132401324013240132401324013240132401324013240132401324013240132401324013240
010400000733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330
010100001303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030130301303013030
01010000132400e2400e2400e24000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330073300733007330
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013230
010100001323013230132301323013230132301323013230132301323013230132301323013230132301323013230132301323013230132301323013230132301323013230132301323013230132301323013230
__music__
00 00010244
00 03040544
01 06070844
00 03090544
00 03054344
00 030a0544
00 030b0544
00 030c0544
00 060d0844
00 030e0544
00 060f0844
00 06100844
00 03110544
00 06120844
00 06130844
00 03140544
00 03150544
00 16171844
00 191a1b44
00 1c1d1e44
00 1f202144
00 22232444
00 1f252144
00 1f262144
00 22272444
00 1f282144
00 22292444
00 1f2a2144
00 1f2b2144
00 222c2444
00 1f2d2144
00 1f2e2144
00 1f2f2144
00 1f302144
00 1f312144
00 32333444
00 35363744
00 38393a44
00 3b3c3d44
00 3b3e3d44
02 3b3f3d44
