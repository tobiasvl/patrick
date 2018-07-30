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
}

function _init()
  mode=modes.title_screen
  score=0
  run=0
  last_mouse=0
  cartdata("tobiasvl_patrick")
  init_board()
  poke(0x5f2d,1)
end

keys={
  [1]=function(x,y) return x>1 and x>patrick.x-1 and x-1 or x,y end,
  [2]=function(x,y) return x<7 and x<patrick.x+1 and x+1 or x,y end,
  [4]=function(x,y) return x,y>1 and y>patrick.y-1 and y-1 or y end,
  [8]=function(x,y) return x,y<4 and y<patrick.y+1 and y+1 or y end,
}

function _update()
  local button=btnp()
  local mouse=stat(34)==1
  local temp_mouse=mouse
  mouse=mouse!=last_mouse and mouse or false
  last_mouse=temp_mouse
  if mode==modes.title_screen then
    if (button==0x10) init_board() mode=modes.play
  elseif mode==modes.play then
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
  end
end

function _draw()
  if mode==modes.title_screen then
    cls()
    center("patrick's",11)
    center("cyberpunk",3)
    center("challenge",8)
    high_score=dget(1)
    high_run=dget(2)
    cursor(0,100)
    center("high score: "..high_score,7)
    center("(over "..high_run.." levels)",7)
  elseif mode==modes.play or mode==modes.win or mode==modes.game_over then
    cls()
    local x=0
    print(balls[1][2],x,0,balls[1][1])
    x+=#(tostr(balls[1][2]).." ")*4
    for i=7,2,-1 do
      print(balls[i][2].." ",x,0,balls[i][1])
      x+=#tostr(balls[i][2].." ")*4
    end
    if (destroyed==0) print("x: reset",128-(8*4),0,7)
    local offset=10
    for y=1,4 do
      for x=1,7 do
        local tile=get_tile(x,y)
        if tile>=0 then
          rect(18*(x-1),offset+(18*(y-1)),18*(x),offset+(18*(y)),7)
          local bg=5
          if ((x==patrick.x-1 or x==patrick.x or x==patrick.x+1) and (y==patrick.y-1 or y==patrick.y or y==patrick.y+1)) bg=2
          if (patrick.x==x and patrick.y==y) bg=0
          if (highlight.x==x and highlight.y==y) bg=14
          local highlighted_tile=get_tile(highlight.x,highlight.y)
          if highlighted_tile>0 then
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
    spr(1,(18*(patrick.x-1))+2,offset+(18*(patrick.y-1))+2,2,2)
    palt()
    print("level "..run+1,0,88,7)
    print("score "..score,0,94,7)
    print("win  +"..60-steps,0,100,5)
    print("lose -"..60+steps,0,106,5)
    print("legend",86,88,6)
    spr(5,86,94,2,2)
    spr(7,86,108,2,2)
    spr(11,100,94,2,2)
    spr(9,100,108,2,2)
    spr(32,114,94,2,2)
    spr(13,114,108,2,2)
    spr(36,stat(32),stat(33))
  end
  if mode==modes.win then
    print("z: next",128-(7*4),0,7)
    print("score "..score,0,94,5)
    print("win  +"..60-steps,0,100,11)
    print("score="..score+(60-steps),0,114,7)
  elseif mode==modes.game_over then
    print("z: next",128-(7*4),0,7)
    print("score "..score,0,94,5)
    print("lose -"..60+steps,0,106,8)
    print("score="..max(0,score-(60+steps)),0,114,7)
    if patrick.x==1 then
      spr(34,(18*(patrick.x-2))+32,10+(18*(patrick.y-2))+9,2,2,true)
      print("oh\nno",(18*(patrick.x-2))+36,10+(18*(patrick.y-2))+10,0)
    else
      spr(34,(18*(patrick.x-2))+9,10+(18*(patrick.y-2))+9,2,2)
      print("oh\nno",(18*(patrick.x-2))+13,10+(18*(patrick.y-2))+10,0)
    end
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

function init_board()
  balls={
    {7,flr(rnd(28))+1},
    {9,flr(rnd(29))},
    {8,flr(rnd(29))},
    {11,flr(rnd(29))},
    {1,flr(rnd(29))},
    {12,flr(rnd(29))},
    {10,flr(rnd(29))}
  }
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
  highlight.x,highlight.y=patrick.x,patrick.y
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
00000000666665555556666666666333333666667777777777777000777777777777700077777777777770007777777777777000777777777777700000000000
00000000665555555555556666333333333333667000700070007000700076667666700076667666700070007666766676667000700076667000700000000000
00700700666444444444466666644444444446667000700070007000700076667666700076667666700070007666766676667000700076667000700000000000
00077000664aaaaaaaaa44666644aaaaaaaaa4667000700070007000700076667666700076667666700070007666766676667000700076667000700000000000
00077000660000000000006666aaccaaaaccaa667777777777777000777777777777700077777777777770007777777777777000777777777777700000000000
0070070066aa00a0aa00aa6666aac0a0aac0aa6676667aaa7666700070007bbb7666700076667ccc700070007666788876667000700071117000700000000000
0000000066aaaaa0aaaaaa6666aaaaa0aaaaaa6676667aaa7666700070007bbb7666700076667ccc700070007666788876667000700071117000700000000000
0000000066aaaaa00aaaaa6666aaaaa00aaaaa6676667aaa7666700070007bbb7666700076667ccc700070007666788876667000700071117000700000000000
00000000666aaaaaa88aa666666aa8aaaa8aa6667777777777777000777777777777700077777777777770007777777777777000777777777777700000000000
000000006666aaaaaaaa66666666aa8888aa66667666766676667000700076667666700076667666700070007000700070007000700076667000700000000000
00000000666666555566666666666633336666667666766676667000700076667666700076667666700070007000700070007000700076667000700000000000
00000000665555555555556666333333333333667666766676667000700076667666700076667666700070007000700070007000700076667000700000000000
00000000655655555555655663363333333363367777777777777000777777777777700077777777777770007777777777777000777777777777700000000000
00000000655655555555655663363333333363360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666655666655666666663366663366660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666655666655666666663366663366660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777770000777777777777770300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007000700070007777777777777777330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007000700070007777777777777777333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007000700070007777777777777777333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777770007777777777777777333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76667999766670007777777777777777333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76667999766670007777777777777777300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76667999766670007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777770007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007000700070007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007000700070007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007000700070007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777770000777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
