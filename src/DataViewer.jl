module DataViewer
using Colors
using GLVisualize, Reactive, GLAbstraction, GeometryTypes, GLFW

function transmat(x, pressed)
    c = !isempty(pressed)
		if c
			return translationmatrix(Vec3f0(x, 0)) * scalematrix(Vec3f0(0.7))
		else
			return scalematrix(Vec3f0(1.0))
		end
end

function viewdata(data::Array{Float64,1},t::AbstractArray{Float64,1}=linspace(0,1,length(data)))
	points = Array(Point2f0, length(data))
	window = glscreen("DataViewer", resolution=(1024,800))
	println(window)
	res = widths(window)
#	window_height = map(window.inputs[:window_area]) do _area
#		_area.h -40
#	end 
#	window_width = map(window.inputs[:window_area]) do _area
#		_area.w -20
#	end
	h = res[2]-40 #ymargins
	mi,mx = extrema(data)
	Δx = mx-mi
	Δt = (res[1]-20)/length(data)
	for i in 1:length(data)
		points[i] = Point2f0(10.0 + (i-1)*Δt, h*(data[i]-mi)/Δx + 20)
	end
	#_scale = scalematrix(Vec3f0(1.5, 1.0, 1.0))
	@materialize mouseposition, mouse_buttons_pressed,mouse_button_down, mouse_button_released,scroll = window.inputs
	#left_pressed  = const_lift(GLAbstraction.pressed, mouse_buttons_pressed, GLFW.MOUSE_BUTTON_LEFT)
	#left_released = const_lift(x->x!=0, mouse_button_released)
	#left_down = const_lift(x->x!=0, mouse_button_down)
	#xytranslate   = GLAbstraction.dragged(mouseposition, left_pressed, true)
	#start_position = filterwhen(left_down, Vec2f0(0.0), mouseposition)
	#end_position = filterwhen(left_released, Vec2f0(0.0), mouseposition)
	fscroll = droprepeats(map(Vec2f0, scroll))
	pan = foldp(+, Vec2f0(0.0),  fscroll)

	start_position = map(mouse_button_down) do button
		value(mouseposition)
	end
	end_position = map(mouse_button_released) do button
		ΔX = value(mouseposition)[1] - value(start_position)[1]
		s = scalematrix(Vec3f0(1.0))
		if ΔX > 0
			s = translationmatrix(-Vec3f0(value(start_position)[1],0.0, 0.0))
			t = scalematrix(Vec3f0(h/ΔX,1.0, 1.0))
			s = s*t
		else
			push!(pan, Vec2f0(0.0))
		end
		s
	end

	selection_rectangle = map(mouse_buttons_pressed) do button
		ΔX = abs(value(mouseposition)[1] - value(start_position)[1])
		ΔY = float(h)
		if value(mouseposition)[1] > value(start_position)[1]
			x = value(start_position)[1]
		else
			x = value(mouseposition)[1]
		end
		S = SimpleRectangle(x, 20.0, ΔX, ΔY)
		S
	end

	new_model = map(pan,end_position) do _pan,_pos
		t = translationmatrix(Vec3f0(_pan[1], 0.0, 0.0))
		s = value(_pos)*t
		s
	end

	_view(visualize(points, :lines, color=RGBA(0.0, 0.0, 0.0, 1.0),model=new_model), window)
	_view(visualize(value(selection_rectangle), model=end_position), window)
	renderloop(window)
end


end#moduel
