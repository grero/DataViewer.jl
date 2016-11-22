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

	start_position = map(mouse_button_down) do button
		value(mouseposition)
	end
	end_position = map(mouse_button_released) do button
		ΔX = value(mouseposition)[1] - value(start_position)[1]
		s = scalematrix(Vec3f0(1.0))
		if ΔX > 0
			t = translationmatrix(-Vec3f0(value(start_position)[1],0.0, 0.0))
			s = scalematrix(Vec3f0(h/ΔX,1.0, 1.0))
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

	_view(visualize(points, :lines, color=RGBA(0.0, 0.0, 0.0, 1.0),model=new_model), window)
	renderloop(window)
end

end#moduel
