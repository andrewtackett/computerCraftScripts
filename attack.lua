print("Starting Attack")
while true do
    for _=1,100 do
        turtle.attack()
    end
    turtle.turnLeft()
    turtle.turnLeft()
    for i=1,16 do
        turtle.select(i) 
        turtle.drop()
    end
    turtle.turnLeft()
    turtle.turnLeft()
end