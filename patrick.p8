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
  win_custom=8,
  game_over_custom=9,
  custom_list=10,
  ending=11,
}

play_modes={
  challenge=1,
  infinite=2,
  custom=3
}

balls={
  {id=1,color=7,pos=0},
  {id=2,color=9,pos=0},
  {id=3,color=8,pos=0},
  {id=4,color=11,pos=0},
  {id=5,color=1,pos=0},
  {id=6,color=12,pos=0},
  {id=7,color=10,pos=0}
}

function _init()
  n=15
  w=127
  t=0
  mode=modes.title_screen
  menu_selection=1
  score=0
  run=0
  last_mouse,last_x,last_y=0,0,0
  cartdata("tobiasvl_patrick")
  high_reldni=dget(0)
  high_score=dget(1)
  high_run=dget(2)
  high_custom=dget(3)
  poke(0x5f2d,1)
  title_dir=true
  emulated=stat(102)!=0
  keyboard=stat(102)!=0 and stat(102)!="www.lexaloffle.com" and stat(102)!="www.playpico.com"
  buttons={o=keyboard and "z" or "🅾️",x=keyboard and "x" or "❎"}
  story_scroll=127
  kill=false
  mouse_pointer=0
  fred=0
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
  custom_score=0
  custom_levels=load_custom()
  custom_list_selected=1
  custom_page=flr(custom_list_selected/20)

  levels={}
  level_number=0

  main_menu={
    {function()
      menu=play_menu
    end, "play"},
    {function()
      init_board(true)
      page=1
      mode=modes.tutorial
      music(-1)
    end, "tutorial"},
    {function()
      story_scroll=127
      mode=modes.story
    end, "story"},
    {function()
      init_board(true,true)
      mode=modes.custom_list
      music(-1)
    end, "edit custom"}
  }
  play_menu={
    {function()
      init_board()
      play_mode=play_modes.infinite
      mode=modes.play
      music(-1)
    end, "infinite mode"},
    {function()
      levels=preset_levels
      level_number=1
      play_mode=play_modes.challenge
      init_board(false,false,levels[level_number])
      mode=modes.play
      music(-1)
    end, "challenge mode"},
  }

  menu=main_menu

  keys={
    [1]=function(x,y) return x>1 and x>patrick.x-1 and x-1 or x,y end,
    [2]=function(x,y) return x<7 and x<patrick.x+1 and x+1 or x,y end,
    [4]=function(x,y) return x,y>1 and y>patrick.y-1 and y-1 or y end,
    [8]=function(x,y) return x,y<4 and y<patrick.y+1 and y+1 or y end,
  }
end

kls=cls
function cls()
  if (not kill) kls()
end

-->8
-- _update()
function _update()
  if (run>127 or fred>7) kill=true
  local mouse=stat(34)==1
  local temp_mouse=mouse
  mouse=mouse!=last_mouse and mouse or false
  last_mouse=temp_mouse
  if mode==modes.title_screen then
    menuitem(1)

    play_menu[3]=#custom_levels>0 and {function()
      levels=custom_levels
      level_number=1
      play_mode=play_modes.custom
      init_board(false,false,levels[level_number])
      mode=modes.play
      music(-1)
    end, "custom levels"} or nil

    if (btnp(2)) menu_selection=menu_selection==1 and #menu or menu_selection-1
    if (btnp(3)) menu_selection=(menu_selection%#menu)+1
    if (btnp(4)) menu_selection=1 menu=main_menu
    if (btnp(5)) menu[menu_selection][1]()
    local x,y=stat(32),stat(33)
    if x!=old_x or y!=old_y or mouse then
      old_x,old_y=x,y
      if x>=47 and x<=69 and y>=30 and y<=34 then
        menu_selection=1
      elseif x>=47 and x<=85 and y>=36 and y<=40 then
        menu_selection=2
      elseif x>=47 and x<=73 and y>=42 and y<=46 then
        menu_selection=3
      elseif x>=47 and x<=77 and y>=48 and y<=52 then
        menu_selection=4
      end
    end
    if mouse then
      if x>=15 and x<=20 and y>=3 and y<=10 then
        fred+=1
      else
        menu[menu_selection][1]()
      end
      mouse=false
    end
  elseif mode==modes.play then
    local button=btnp()
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
    if play_mode==play_modes.infinite and button==0x10 and destroyed==0 then
      init_board(false,false,levels[level_number])
    end
    if destroyed==27 then
      sfx(25)
      mode=modes.win
    elseif get_tile(patrick.x-1,patrick.y)==-1 and get_tile(patrick.x+1,patrick.y)==-1 and get_tile(patrick.x-1,patrick.y-1)==-1 and get_tile(patrick.x,patrick.y-1)==-1 and get_tile(patrick.x+1,patrick.y-1)==-1 and get_tile(patrick.x-1,patrick.y+1)==-1 and get_tile(patrick.x,patrick.y+1)==-1 and get_tile(patrick.x+1,patrick.y+1)==-1 then
      sfx(8)
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
      local x,y=stat(32),stat(33)
      if x!=old_x or y!=old_y or mouse then
        old_x,old_y=x,y
        x,y=ceil(x/18),ceil((y-10)/18)
        new_highlight.x=(x==patrick.x-1 or x==patrick.x or x==patrick.x+1) and x or 0
        new_highlight.y=(y==patrick.y-1 or y==patrick.y or y==patrick.y+1) and y or 0
      end
    end
    if get_tile(new_highlight.x,new_highlight.y)>=0 then
      highlight=new_highlight
    end
    if (button==0x20 or mouse) and not (highlight.x==patrick.x and highlight.y==patrick.y) then
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
    if btnp(5) or mouse then
      score+=60-steps
      if play_mode==play_modes.infinite then
        run+=1
        if (score>high_score) dset(1,score) dset(2,run)
      elseif play_mode==play_modes.challenge then
        if level_number<#levels then
          level_number+=1
        else
          mode=modes.ending
        end
      end
      init_board(false,false,levels[level_number])
      mode=modes.play
      mouse=false
    end
  elseif mode==modes.game_over then
    if btnp(5) or mouse then
      score=max(0,score-60+steps)
      if play_mode==play_modes.infinite then
        run+=1
        if (score>high_score) dset(1,score) dset(2,run)
      end
      init_board(false,false,levels[level_number])
      mode=modes.play
      mouse=false
    end
  elseif mode==modes.win_custom or mode==modes.game_over_custom then
    if btnp(5) or mouse then
      mode=modes.custom
      mouse=false
    end
  elseif mode==modes.tutorial then
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
    if btnp(5) or mouse then
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
    if patrick.x>0 and btnp(5) then
      if not custom_levels[custom_list_selected] then
        custom_levels[custom_list_selected]={}
      end
      custom_levels[custom_list_selected][1]=balls[1].pos
      for i=2,7 do
        custom_levels[custom_list_selected][7-(i-2)]=balls[i].pos
      end
      save_custom()
      mode=modes.custom_list
    end
    if mouse then
      local x,y=stat(32),stat(33)
      if old_x!=x or old_y!=y or mouse then
        old_x,old_y=x,y
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
        elseif get_tile(cell_x,cell_y)==0 and mouse_pointer>0 then
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
  elseif mode==modes.custom_list then
    if btnp(2) then
      if (custom_list_selected>1) custom_list_selected-=1
      if (custom_list_selected<(custom_page*20)+1) custom_page-=1
    end
    if btnp(3) then
      if (custom_list_selected<50 and custom_levels[custom_list_selected]!=nil) custom_list_selected+=1
      if (custom_list_selected>(custom_page*20)+20) custom_page+=1
    end
    if (btnp(4)) mode=modes.title_screen
    if btnp(5) then
      local empty_level=custom_levels[custom_list_selected]==nil
      init_board(empty_level,empty_level,custom_levels[custom_list_selected])
      mode=modes.custom
    end
  elseif mode==modes.ending then
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
  end
end

-->8
-- _draw()
function _draw()
  if mode==modes.title_screen then
    local x,y=stat(32),stat(33)
    cls()

    if (fred==1) print("fred?",15,3)
    if (fred==2) print("fred\nwho?",15,3)
    if (fred==3) print("freddie\nfinkle?",15,3)
    if (fred==4) print("that\nbastard",15,3)

    outline("patrick's",0,2,11,7,true)
    outline("cyberpunk",0,9,3,11,true)
    outline("challenge",0,16,8,0,true)

    cursor(35,45)
    for i=1,#menu do
      color(menu_selection==i and 10 or 14)
      if (menu_selection==i) then
        print(">"..menu[i][2].."_")
      else
        print(menu[i][2])
      end
    end
    cursor(0,73)

    if menu==main_menu then
      if (flr(time())%2==0) center("\npress "..buttons.x,6)
    else
      color()
      if menu_selection==1 then
        center("high score: "..high_score,7)
        center("(run: "..high_run.." levels)",7)
      else
        center("high score: "..(menu_selection==2 and high_reldni or high_custom),7)
      end
    end

    cursor(0,107)
    center("by",5)
    center("tobiasvl",5)

    local title_y=90
    t-=.5
    for i=0,n do
      local z=(i*n+t%n)
      local y=w*n/z+32

      line(0,title_y-5,127,title_y-5,1)
      line(0,title_y-4,127,title_y-4,2)
      line(0,title_y-3,127,title_y-3,13)
      line(0,title_y-2,127,title_y-2,9)
      line(0,title_y-1,127,title_y-1,10)
      line(0,title_y,127,title_y,14)
      line(0,title_y+6,127,title_y+6,14)
      line(0,title_y+16,127,title_y+16,14)
      line(0,title_y+28,127,title_y+28,14)
      line(0,title_y+46,127,title_y+46,14)

      local v=i+t%n/n-n/2
      line(v*9+64,title_y,v*60+64,w,14)
    end

    if x>=15 and x<=18 and y>=3 and y<=6 then
      spr(15,x,y,1,2)
    else
      if (not emulated) spr(16,x,y)
    end
  elseif mode==modes.tutorial then
    cls()
    local s=buttons.x..": next"
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
      print("select square: ⬅️⬇️➡️  move: "..buttons.x)
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
  elseif mode==modes.play or mode==modes.win or mode==modes.game_over then
    cls()
    print_code()
    if (destroyed==0 and play_mode==play_modes.infinite) local s=buttons.o..": skip" print(s,128-((keyboard and 7 or 8)*4),0,7)
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
    if play_mode==play_modes.infinite then
      print("level"..(kill and "-" or " ")..run+1,0,88,7)
    else
      print("level"..(kill and "-" or " ")..level_number,0,88,7)
    end
    print("score "..score,0,94,7)
    print("win  +"..60-steps,0,100,5)
    print("lose -"..60+steps,0,106,5)
    print_legend()
    if (not emulated) spr(16,stat(32),stat(33))
  end
  if mode==modes.win then
    local s=buttons.x..": next"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("score "..score,0,94,5)
    print("win  +"..60-steps,0,100,11)
    print("score="..score+(60-steps),0,114,7)
    all_right()
  elseif mode==modes.game_over then
    if play_mode==play_modes.infinite then
      local s=buttons.x..": next"
      print(s,128-((keyboard and 7 or 8)*4),0,7)
    else
      local s=buttons.x..": retry"
      print(s,128-((keyboard and 8 or 9)*4),0,7)
    end
    print("score "..score,0,94,5)
    print("lose -"..60+steps,0,106,8)
    print("score="..max(0,score-(60+steps)),0,114,7)
    oh_no()
  elseif mode==modes.win_custom then
    local s=buttons.x..": edit"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("score "..60-steps,0,100,11)
    all_right()
  elseif mode==modes.game_over_custom then
    local s=buttons.x..": edit"
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
        if ball.id!=1 then
          circfill(ball_x,38*6+story_scroll,4,ball.color)
          ball_x+=10
        end
      end
      if (story_scroll<-300) local str="press "..buttons.x print(str,64-(#str*2),64,7)
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
    if (patrick.x>0) local s=buttons.x..": save" print(s,128-((keyboard and 7 or 8)*4),0,7)
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
  elseif mode==modes.ending then
    cls()
    if (story_scroll<-150 and story_scroll>-155) or (story_scroll<-160 and story_scroll>-165) or (story_scroll<-170 and story_scroll>-175) then
      rectfill(0,0,128,128,8)
      palt(0,false)
      palt(6,true)

      pal(0,13)
      pal(10,13)
      pal(7,13)
      pal(8,13)

      spr(41,56,80,2,2)
      spr(43,56,96,2,2)
      pal()
      palt()
    elseif story_scroll<-180 then
      if story_scroll>-190 then
        pal(6,1)
        pal(0,13)
        pal(10,13)
        pal(7,13)
        pal(8,13)
      elseif story_scroll>-200 then
        pal(6,5)
        pal(0,6)
        pal(10,6)
        pal(7,6)
        pal(8,6)
      end
      rectfill(0,0,128,128,6)
      palt(0,false)
      palt(6,true)
      if story_scroll>-250 then
        spr(41,56,80,2,2)
        spr(43,56,96,2,1)
        spr(59,56,96+8,2,1)
      elseif story_scroll<-250 then
        spr(41,story_scroll+250+56,80,2,2)
        spr(43,story_scroll+250+56,96,2,1)
        spr(flr(story_scroll)%2==0 and 59 or 45,story_scroll+250+56,96+8)
        spr(flr(story_scroll)%2!=0 and 60 or 61,story_scroll+250+56+8,96+8)
      end
      pal()
      palt()
      if story_scroll<-200 then
        --trapdoor
        line(56,0,40,8,0)
        line(72,0,88,8,0)
        --sign
        rect(68,12,114,30,0)
        rectfill(69,13,113,29,5)
        pset(70,14,0)
        pset(70,28,0)
        pset(112,28,0)
        pset(112,14,0)
        print("vinnie's",80,16,6)
        print("tomb",88,22,6)
        --arrow
        line(74,16,74,26,6)
        line(74,16,70,20,6)
        line(74,16,78,20,6)
        line(0,112,128,112,0)
        --screen
        rectfill(14,43,112,57,0)
        rectfill(15,42,111,58,0)
        --ground and drops
        rectfill(0,113,128,128,5)
        local x,y=flr(rnd(127)),flr(rnd(127))
        line(x,y,x,y+3,12)
      end
      if story_scroll<-220 and story_scroll>-240 then
        spr(36,50,65,3,2,true)
        print("where\nam i?",52,66,0)
      end
      if story_scroll<-150 then
        if flr(story_scroll)%3!=0 then
          cursor(0,45)
          center("warning:",8)
          center("power failure in cryo #1",8)
        end
      end
    end
    local story={
      "patrick has made it.",
      "",
      "",
      "he has hacked the sinister zebra",
      "corporation's virtual reality",
      "system, and gained access to",
      "their mainframe.",
      "",
      "",
      "as the tomb bot factories shut",
      "down all over fun land, ernie",
      "york's electronic weather",
      "systems also lose power, and",
      "the rain finally ends after",
      "several decades.",
      "",
      "",
      "unbeknown to patrick, deep in",
      "the underworld, underneath the",
      "fabled vinnie's tomb, one of",
      "ernie york's cryogenics chambers",
      "also shuts down..."
    }
    local scroll_offset=0
    for str in all(story) do
      print(str,64-(#str*2),story_scroll+scroll_offset)
      if story_scroll>-4 then
        local x,y=flr(rnd(127)),flr(rnd(127))
        line(x,y,x-3,y-3,7)
      end
      scroll_offset+=6
    end
  elseif mode==modes.custom_list then
    cls()
    for i=(custom_page*20)+1,min((custom_page*20)+20,50) do
      local code=""
      if i<=#custom_levels+1 then
        if custom_list_selected==i then
          color(14)
        else
          if (i<=#custom_levels) color(10) else color(6)
        end
        for j in all(custom_levels[i]) do
          code=code.." "..(j<10 and " " or "")..j
        end
      else
        color(5)
      end
      print((custom_list_selected==i and ">" or "")..i.." "..(i==#custom_levels+1 and stat(95)%2==0 and "_" or "")..(i<10 and " " or "")..code)
    end

    if (custom_page>0) print("\148",120,0,7)
    if ((custom_page*20)+20<#custom_levels) print("\131",120,114,7)

    print(buttons.x,113,60,7)
    if custom_levels[custom_list_selected] then
      print("edit",109,66,7)
    else
      print("create",105,66,7)
    end
  end
  if page==12 and run==0 then
    print("good\nluck",50,94,11)
  elseif kill and run==130 then
    print(" kill\nscreen",44,94,8)
  end
end

-->8
-- misc functions
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

function outline(s,x,y,c1,c2,center)
 if center then
  x=64-(#s*2)
 end
	for i=0,2 do
	 for j=0,2 do
	  if not(i==1 and j==1) then
	   print(s,x+i,y+j,c1)
	  end
	 end
	end
	print(s,x+1,y+1,c2)
end

-->8
-- init_board
function init_board(skip_balls,skip_patrick,level)
  if not level then
    if not skip_balls then
      for ball in all(balls) do
        ball.pos=flr(rnd(28))+1
      end
    end
    if (not skip_patrick) balls[1].pos=flr(rnd(28))+1 else patrick={x=-1,y=-1}
  else
    balls[1].pos=level[1]
    for i=2,7 do
      balls[i].pos=level[7-(i-2)]
    end
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
        if (location==ball.pos) then
          if (ball.id==1) patrick={x=x,y=y} else set_tile(x,y,ball.id)
          break
        end
      end
    end
  end
  if (not skip_patrick) highlight.x,highlight.y=patrick.x,patrick.y
end

-->8
-- custom level routines
-- custom levels are stored as packed bytes:
-- 5 bits per ball, 7 balls per level

-- save custom levels as packed bytes
-- we enqueue 5-bit balls in a fifo, and dequeue 8-bit bytes
function save_custom()
  local addr=0x5e10 --first four numbers are used for hiscores
  local level_num=1 --current level number
  local level=custom_levels[level_num] --current level
  local ball_num=1 --current ball in level
  local byte_queue,queue_length=0,0 --fifo queue of bytes to be saved

  while level do
    local ball=level[ball_num]

    -- pack ball at end of queue
    byte_queue=rotl(byte_queue,5)
    byte_queue=bor(byte_queue,ball)
    queue_length+=5

    -- queue contains a full byte
    if queue_length>=8 then
      -- rotate rest of queue to after decimal point
      byte_queue=rotr(byte_queue,queue_length-8)
      -- save byte
      printh("poking "..addr)
      poke(addr,byte_queue)
      addr+=1
      -- dequeue byte
      byte_queue=band(byte_queue,0xff00.ffff)
      -- restore queue
      byte_queue=rotl(byte_queue,queue_length-8)
      queue_length-=8
    end

    ball_num+=1

    -- a full level has been saved
    if ball_num>7 then
      level_num+=1
      level=custom_levels[level_num]
      ball_num=1
    end
  end

  -- empty the queue
  if queue_length!=0 then
    poke(addr,rotl(byte_queue,8-queue_length))
  end
end

-- load packed bytes into levels
-- we enqueue 8-bit bytes from a fifo, and dequeue 5-bit balls
function load_custom()
  local levels,level={},{}
  local addr=0x5e10 --first four numbers are used for hiscores
  local ball_queue,queue_length=0,0 --fifo queue of balls/bytes to be loaded

  -- read all cartridge save data
  while #levels<=50 and addr<0x5f00 do
    local byte=peek(addr)
    addr+=1

    -- enqueue byte
    ball_queue=rotl(ball_queue,8)
    ball_queue=bor(byte,ball_queue)
    queue_length+=8

    -- queue contains a full ball
    while queue_length>=5 do
      -- rotate rest of queue after decimal point
      ball_queue=rotr(ball_queue,queue_length-5)
      -- load ball
      add(level,band(ball_queue,0b11111))
      -- dequeue ball
      ball_queue=band(ball_queue,0b1111111111100000.1111111111111111)
      -- restore queue
      ball_queue=rotl(ball_queue,queue_length-5)
      queue_length-=5
      if (#level==7) break
    end

    -- a full level has been loaded
    if #level==7 then
      -- save loaded level unless patrick's not present
      -- (avoid loading empty levels)
      if level[1]!=0 then
        add(levels,level)
      end
      level={}
    end
  end
  -- the queue should always be empty at this point
  assert(queue_length==0)
  return levels
end

-->8
-- reldni levels
-- http://web.archive.org/web/20020127141411fw_/http://www.reldni.com:80/archive/patrick2.html
preset_levels={
  {27,7,25,6,26,1,15},
  {14,11,5,16,11,6,13},
  {12,27,24,1,10,18,13},
  {20,23,21,28,1,9,21},
  {12,15,13,19,21,1,13},
  {28,14,8,19,14,9,16},
  {8,17,19,20,16,1,10},
  {6,19,13,24,18,13,21},
  {20,11,11,4,25,11,23},
  {1,11,9,23,20,18,6},
  {27,14,8,19,14,9,16},
  {19,22,20,27,28,8,20},
  {2,27,21,4,27,22,1},
  {13,16,14,20,22,2,14},
  {20,18,12,23,17,12,20},
  {25,28,26,5,6,14,26},
  {5,11,11,4,25,11,23},
  {27,10,7,1,18,23,23},
  {4,12,2,11,4,6,20},
  {28,7,25,7,27,1,15},
  {18,25,4,17,14,8,19},
  {3,11,5,16,11,6,13},
  {4,20,16,10,0,0,6},
  {27,8,9,11,6,20,28},
  {5,16,19,23,17,6,11},
  {9,8,17,19,21,16,2},
  {13,20,19,9,17,2,2},
  {20,19,16,26,24,8,20},
  {6,15,17,18,14,27,7},
  {27,20,25,10,23,24,0}, -- ?
  {10,9,5,15,14,26,10},
  {6,10,11,16,1,26,14},
  {27,17,20,3,7,1,18},
  {10,20,17,12,1,5,6},
  {11,19,9,18,11,13,27},
  {4,18,24,21,3,1,13},
  {27,10,7,1,18,23,23},
  {12,20,10,19,12,14,28},
  {18,4,26,9,4,27,7},
  {10,20,17,11,1,5,6},
  {27,14,8,19,14,9,16},
  {14,22,12,21,13,16,2},
  {16,4,26,9,4,27,7},
  {12,0,0,11,0,19,13},
  {24,2,13,20,13,6,21},
  {8,21,15,26,21,16,23},
}
__gfx__
0000000066666555555666666666633333366666eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee00000999900
0000000066555555555555666633333333333366e000e000e000e000e000e222e222e000e222e222e000e000e222e222e222e000e000e222e000e00009aaaa90
0070070066644444444446666664444444444666e000e000e000e000e000e222e222e000e222e222e000e000e222e222e222e000e000e222e000e0009aaaaaa9
00077000664aaaaaaaaa44666644aaaaaaaaa466e000e000e000e000e000e222e222e000e222e222e000e000e222e222e222e000e000e222e000e0009aaaaaa9
00077000660000000000006666aaccaaaaccaa66eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee0009a6aa6a9
0070070066aa00a0aa00aa6666aac0a0aac0aa66e222eaaae222e000e000ebbbe222e000e222eccce000e000e222e888e222e000e000e111e000e0009a6aa6a9
0000000066aaaaa0aaaaaa6666aaaaa0aaaaaa66e222eaaae222e000e000ebbbe222e000e222eccce000e000e222e888e222e000e000e111e000e000096aa690
0000000066aaaaa00aaaaa6666aaaaa00aaaaa66e222eaaae222e000e000ebbbe222e000e222eccce000e000e222e888e222e000e000e111e000e00000966900
30000000666aaaaaa88aa666666aa8aaaa8aa666eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee00000555500
330000006666aaaaaaaa66666666aa8888aa6666e222e222e222e000e000e222e222e000e222e222e000e000e000e000e000e000e000e222e000e00000566500
3330000066666655556666666666663333666666e222e222e222e000e000e222e222e000e222e222e000e000e000e000e000e000e000e222e000e00000555500
3333000066555555555555666633333333333366e222e222e222e000e000e222e222e000e222e222e000e000e000e000e000e000e000e222e000e00000566500
3333300065565555555565566336333333336336eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee000eeeeeeeeeeeee00000055000
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
__label__
77700000aaa00000ccc0ccc0000011100000bb00bb00000088008880000099009990000000000000000000000000000000000000000000000000000000000000
0070000000a0000000c0c0c00000100000000b000b00000008000080000009009000000000000000000000000000000000000000000000000000000000000000
0770000000a00000ccc0c0c00000111000000b000b00000008000880000009009990000000000000000000000000000000000000000000000000000000000000
0070000000a00000c000c0c00000001000000b000b00000008000080000009000090000000000000000000000000000000000000000000000000000000000000
7770000000a00000ccc0ccc0000011100000bbb0bbb0000088808880000099909990000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222221112222222e22222222222222222e2222222aaa2222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222111111122222e22222222222222222e22222aaaaaaa22222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222111111122222e22222222222222222e22222aaaaaaa22222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22221111111112222e22222222222222222e2222aaaaaaaaa2222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22221111111112222e22222222222222222e2222aaaaaaaaa2222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22221111111112222e22222222222222222e2222aaaaaaaaa2222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222111111122222e22222222222222222e22222aaaaaaa22222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222111111122222e22222222222222222e22222aaaaaaa22222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222221112222222e22222222222222222e2222222aaa2222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0
e22222222222222222e55555555555555555e00000000000000000e66666666666666666e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000055555500000e66666666666666666e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00055555555555500e66666666666666666e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00004444444444000e66666666666666666e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e0004aaaaaaaaa4400e6666666bbb6666666e22222222222222222e22222228882222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e66666bbbbbbb66666e22222222222222222e22222888888822222e22222222222222222e0
e22222222222222222e55555555555555555e000aa00a0aa00aa00e66666bbbbbbb66666e22222222222222222e22222888888822222e22222222222222222e0
e22222222222222222e55555555555555555e000aaaaa0aaaaaa00e6666bbbbbbbbb6666e22222222222222222e22228888888882222e22222222222222222e0
e22222222222222222e55555555555555555e000aaaaa00aaaaa00e6666bbbbbbbbb6666e22222222222222222e22228888888882222e22222222222222222e0
e22222222222222222e55555555555555555e0000aaaaaa88aa000e6666bbbbbbbbb6666e22222222222222222e22228888888882222e22222222222222222e0
e22222222222222222e55555555555555555e00000aaaaaaaa0000e66666bbbbbbb66666e22222222222222222e22222888888822222e22222222222222222e0
e22222222222222222e55555555555555555e00000005555000000e66666bbbbbbb66666e22222222222222222e22222888888822222e22222222222222222e0
e22222222222222222e55555555555555555e00055555555555500e6666666bbb6666666e22222222222222222e22222228882222222e22222222222222222e0
e22222222222222222e55555555555555555e00550555555550550e66666666666666666e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00550555555550550e66666666666666666e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000550000550000e66666666666666666e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000550000550000e66666666666666666e22222222222222222e22222222222222222e22222222222222222e0
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222229992222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e2222222ccc2222222e22222222222222222e0
e22222999999922222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222ccccccc22222e22222222222222222e0
e22222999999922222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222ccccccc22222e22222222222222222e0
e22229999999992222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e2222ccccccccc2222e22222222222222222e0
e22229999999992222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e2222ccccccccc2222e22222222222222222e0
e22229999999992222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e2222ccccccccc2222e22222222222222222e0
e22222999999922222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222ccccccc22222e22222222222222222e0
e22222999999922222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222ccccccc22222e22222222222222222e0
e22222229992222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e2222222ccc2222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e55555555555555555e00000000000000000e55555555555555555e22222222222222222e22222222222222222e22222222222222222e0
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e22222222222222222e0
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007770707077707000000077000000000000000000000000000000000000000000000000000000000000600066600660666066006600000000000000000000
70007000707070007000000007000000000000000000000000000000000000000000000000000000000000600060006000600060606060000000000000000000
70007700707077007000000007000000000000000000000000000000000000000000000000000000000000600066006000660060606060000000000000000000
70007000777070007000000007000000000000000000000000000000000000000000000000000000000000600060006060600060606060000000000000000000
77707770070077707770000077700000000000000000000000000000000000000000000000000000000000666066606660666060606660000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700770077077707770000077700000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0eeeeeeeeeeeee0eeeeeeeeeeeee0
70007000707070707000000070700000000000000000000000000000000000000000000000000000000000e000e000e000e0e222e222e222e0e000e000e000e0
77707000707077007700000070700000000000000000000000000000000000000000000000000000000000e000e000e000e0e222e222e222e0e000e000e000e0
00707000707070707000000070700000000000000000000000000000000000000000000000000000000000e000e000e000e0e222e222e222e0e000e000e000e0
77000770770070707770000077700000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0eeeeeeeeeeeee0eeeeeeeeeeeee0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e222eaaae222e0e222e888e222e0e222e999e222e0
50505550550000000000000055505550000000000000000000000000000000000000000000000000000000e222eaaae222e0e222e888e222e0e222e999e222e0
50500500505000000000050050005050000000000000000000000000000000000000000000000000000000e222eaaae222e0e222e888e222e0e222e999e222e0
50500500505000000000555055505550000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0eeeeeeeeeeeee0eeeeeeeeeeeee0
55500500505000000000050000500050000000000000000000000000000000000000000000000000000000e222e222e222e0e000e000e000e0e000e000e000e0
55505550505000000000000055500050000000000000000000000000000000000000000000000000000000e222e222e222e0e000e000e000e0e000e000e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e222e222e222e0e000e000e000e0e000e000e000e0
50000550055055500000000050005500000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0eeeeeeeeeeeee0eeeeeeeeeeeee0
50005050500050000000000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50005050555055000000555055500500000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0eeeeeeeeeeeee0eeeeeeeeeeeee0
50005050005050000000000050500500000000000000000000000000000000000000000000000000000000e000e222e222e0e222e222e000e0e000e222e000e0
55505500550055500000000055505550000000000000000000000000000000000000000000000000000000e000e222e222e0e222e222e000e0e000e222e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000e222e222e0e222e222e000e0e000e222e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0eeeeeeeeeeeee0eeeeeeeeeeeee0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000ebbbe222e0e222eccce000e0e000e111e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000ebbbe222e0e222eccce000e0e000e111e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000ebbbe222e0e222eccce000e0e000e111e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0eeeeeeeeeeeee0eeeeeeeeeeeee0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000e222e222e0e222e222e000e0e000e222e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000e222e222e0e222e222e000e0e000e222e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000e222e222e0e222e222e000e0e000e222e000e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0eeeeeeeeeeeee0eeeeeeeeeeeee0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

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
