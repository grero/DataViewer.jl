module DataViewer
using Colors
using GLVisualize, Reactive, GLAbstraction, GeometryTypes, GLFW

"""
Plot `data`. Zoom the horizontal axis by dragging the mouse, pan horizontal by scrolling and reset the view by clicking once anywhere on the plot.

	function viewdata(data::Array{Float64,1},t::AbstractArray{Float64,1}=linspace(0,1,length(data)))
"""
function viewdata{T<:Real}(data::Array{T,1},t::AbstractArray{Float64,1}=linspace(0,1,length(data)))
	window = glscreen("DataViewer", resolution=(1024,800))
	res = widths(window)
	h = res[2]-40 #ymargins
	w = res[1]-20 #xmargin
	mi,mx = extrema(data)
	Δx = mx-mi
	Δt = (res[1]-20)/length(data)

	points = Array(Point2f0, length(data))
	for i in 1:length(data)
		points[i] = Point2f0(10.0 + (i-1)*Δt, h*(data[i]-mi)/Δx + 20)
	end
	@materialize mouseposition, mouse_buttons_pressed,mouse_button_down, mouse_button_released,scroll = window.inputs
	fscroll = droprepeats(map(Vec2f0, scroll))
	pan = foldp(+, Vec2f0(0.0),  fscroll)

	m2id = GLVisualize.mouse2id(window)

	start_position = map(mouse_button_down) do button
		value(mouseposition)
	end
	left_released = filter(button->button == GLFW.MOUSE_BUTTON_LEFT, GLFW.MOUSE_BUTTON_LEFT, mouse_button_released)
	right_released = filter(button->button == GLFW.MOUSE_BUTTON_RIGHT, GLFW.MOUSE_BUTTON_RIGHT, mouse_button_released)


	end_position = map(left_released) do button
		s = scalematrix(Vec3f0(1.0))
		ΔX = value(mouseposition)[1] - value(start_position)[1]
		ΔY = value(mouseposition)[2] - value(start_position)[2]
		if ΔX > 0
			t = translationmatrix(-Vec3f0(value(start_position)[1],value(mouseposition)[2], 0.0))
			s = scalematrix(Vec3f0(w/abs(ΔX),h/abs(ΔY), 1.0))
			s = s*t
		else
			push!(scroll, -value(pan)) #hackish way of reseting the pan signal
		end
		s
	end

	#keep track of scaling
	current_scale = foldp(scalematrix(Vec3f0(1.0)), end_position) do v0, v1
		if v1[1,1] == 1.0
			vnew = v1
		else
			vnew = v1*v0
		end
		vnew
	end

	new_model = map(pan,current_scale) do _pan,_pos
		t = translationmatrix(Vec3f0(_pan[1], 0.0, 0.0))
		s = value(_pos)*t
		s
	end

	_vpoints = visualize(points, :lines, color=RGBA(0.0, 0.0, 0.0, 1.0),model=new_model)
	ids = _vpoints.children[].id
	is_same_id(id,ids) = id == ids
	isoverpoint = droprepeats(const_lift(is_same_id, m2id, ids))

	cursor = map(right_released) do overpoint
		_m2id = value(GLVisualize.mouse2id(window))
		idx,_value = value(GLVisualize.mouse2id(window))
		if idx == ids
			#get the point in the data array, i.e. in pixel values
			rpos = (points[_value-1][1], points[_value-1][2])
			#convert back to data point 
			pos = ((rpos[1]-10)/Δt, (rpos[2]+20)*Δx/h+mi)
			xpos = @sprintf "%.3f" pos[1]
			ypos = @sprintf "%.3f" pos[2]
			_text = "($(xpos), $(ypos))"
		else
			_text = "NAN"
			rpos = (-100.0, -100.0)
		end
		_text, rpos
	end

	cursor_text = map(cursor) do vv
		_text, _pos = vv
		_text
	end

	_text_scale = scalematrix(Vec3f0(5.0, 5.0, 1.0))
	cursor_pos = map(cursor,new_model) do vv,mm
		_text, _pos = vv
		ss = _text_scale
		if !isempty(_text)
			tt = translationmatrix(Vec3f0(value(_pos)[1], value(_pos)[2], 0.0))
			tt = mm*tt
			tt = translationmatrix(Vec3f0(tt[1,4], tt[2,4], 0.0))
		else
			tt = translationmatrix(Vec3f0(0.0))
		end
		tt*ss
	end

	cursor_point = map(cursor) do vv
		_text,_pos = vv
		[Point2f0(_pos[1], _pos[2])]
	end

	#isoverpoint = const_lift(is_same_id, m2id, ids)
	_view(_vpoints, window)
	#TODO: Make the scale conform to some sensitible font size
	_view(visualize(cursor_text, model=cursor_pos), window)
	_view(visualize((Circle, cursor_point), model=new_model,scale=Vec3f0(20.0)), window)
	renderloop(window)
end

end#moduel
