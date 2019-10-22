local vector = require "vector"

light_sensor = nil
motor_ground = nil
robot_state = 0  -- 0 = find light, 1 = reached fire, 2 = following robot, 3 = fleeing from fire

step = 0
local v1 = {}
local v2 = {}


function init()
	L = robot.wheels.axis_length
	robot.leds.set_all_colors("black")
end

function reset()
	robot.leds.set_all_colors("black")
	robot.wheels.set_velocity(0,0)
end

function destroy()
   -- put your code here
end

function step()
	if robot_state == 0 then            
		v1 = vector.vec2_polar_sum(wander(), avoid_obstacle())
        
        v5 = read_range_and_bearing(4)
        v3 = vector.vec2_polar_sum(v1,v5)
        wheels_l, wheels_r = trasformation_vector_to_velocity(v3)
        robot.leds.set_all_colors("white")
		robot.wheels.set_velocity(wheels_l, wheels_r)
		if get_temperature_readings() then
            robot.leds.set_all_colors("red")
			robot_state = 1
		else
			log("")
		end
	elseif robot_state == 1 then
        write_range_and_bearing(3,1)
		robot.wheels.set_velocity(0, 0)
        if check_antenna() then
            robot.leds.set_all_colors("green")
            robot_state = 2
        end
	elseif robot_state == 2 then
		robot.wheels.set_velocity(0, 0)
	else 
		--log("robot in state n")
	end
end

-------------- Controller functions --------------

function wander() 
	log("Robot is in wander state")
	--robot.range_and_bearing.set_data(1, 0)
	return {length = robot.random.uniform(2), angle = robot.random.uniform(-math.pi/4, math.pi/4)} -- TODO: settare il random value
end 

function avoid_obstacle()
	max_proximity_value = 0
	max_proximity_angle = 0
	for _, proximity_sensor in pairs(robot.proximity) do
		if proximity_sensor.value > max_proximity_value then
			max_proximity_value = proximity_sensor.value
			max_proximity_angle = proximity_sensor.angle
		end
	end
    v1 = {length = max_proximity_value * 6, angle = max_proximity_angle + math.pi}
    v2 = {length = max_proximity_value * 2, angle = max_proximity_angle - math.pi/2}
	return vector.vec2_polar_sum(v1,v2)
end

function stop_near_fire()
end        
    

-------------- Extra functions --------------

function trasformation_vector_to_velocity(v)
	v_left = v.length - ((v.angle * L)/2)
	v_right = v.length + ((v.angle * L)/2)
  return v_left, v_right
end

function get_temperature_readings()
  medium_temp = 0
  for _, motor_ground in pairs(robot.motor_ground) do
	  if robot.motor_ground[_].value >= 0.2 and robot.motor_ground[_].value <= 0.7 then
		  medium_temp = medium_temp+1
	  end
  end
  if medium_temp == 4 then
	  return true
  else
	  return false
  end
end

--function countRAB()
	--number_robot_sensed = 0
	--for _, rab in ipairs(robot.range_and_bearing) do
		--if rab.range < 30 and rab.data[1] == 1 then   
			--number_robot_sensed = number_robot_sensed + 1
			--log("in :" .. number_robot_sensed)
		--end
	--end
	--return number_robot_sensed
--end 


function read_range_and_bearing()
    attract = false
    repulse = false
    rabbi = nil
    for _,rab in ipairs(robot.range_and_bearing) do
        if rab.data[4] == 1 and not repulse then  
            attract = true 
            rabbi = rab
        elseif rab.data[4] == 2 and rab.range < 40 then
            repulse = true
            rabbi = rab
        end
    end    
    if attract then
        log("Attraggo")
        return  {length = 4,  angle = rabbi.horizontal_bearing}
    elseif repulse then
        log("Respingo")
        return  {length = 4,  angle = rabbi.horizontal_bearing - math.pi}
    else
    log("Nulla")
     return {length = 0, angle = 0}
    end
    
    
    
    --if closest_rab ~= nil and closest_rab.data[4] == 2 then
       -- log("Respinto")
        --return {length = 4, angle = closest_rab.horizontal_bearing+(math.pi)}
    --elseif closest_rab ~= nil and closest_rab.data[4] == 1 then
        --log("Attratto")
        
    --else
        --log("Non vedo")
        --return {length = 0, angle = 0}
   -- end
end

function write_range_and_bearing(i,n)
    robot.range_and_bearing.set_data(i,n)
end

function count_assisting_robots()
    assisting_robots = 0
    for _,rab in ipairs(robot.range_and_bearing) do
        if rab.data[3] == 1  then
            assisting_robots = assisting_robots + 1
        end
    end
    log("Assisting robots == " .. assisting_robots)
    if assisting_robots >= 3 then
        return true
    else
        return false
    end
end

function check_antenna()
    for _,rab in ipairs(robot.range_and_bearing) do
        if rab.data[6] == 1 and rab.range < 30 then
            return true
        end
    end
    return false
end
