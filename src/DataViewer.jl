module DataViewer
using Colors, FixedSizeArrays
using GLVisualize, Reactive, GLAbstraction, GeometryTypes, GLFW
import GLAbstraction: imagespace

"""
Plot `data`. Zoom the horizontal axis by dragging the mouse, pan horizontal by scrolling and reset the view by clicking once anywhere on the plot.

	function viewdata(data::Array{Float64,1},t::AbstractArray{Float64,1}=linspace(0,1,length(data)))
"""
function viewdata(data::Array{Float64,1},t::AbstractArray{Float64,1}=linspace(0,1,length(data)))
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

	cam = OrthographicPixelCamera(window.inputs)
	window.cameras[:orthographic] = cam
	register_drag_zoom(window.cameras[:orthographic], window)	
	_view(visualize(points, :lines, color=RGBA(0.0, 0.0, 0.0, 1.0)), window,camera=:orthographic)
	renderloop(window)
end


# it's time to have these defined in GeometryTypes
function Rect(x, y, w, h)
    SimpleRectangle(round(Int, x), round(Int, y), round(Int, w), round(Int, h))
end
function Rect(xy::FixedVector, w, h)
    Rect(xy[1], xy[2], w, h)
end
function Rect(x, y, wh::FixedVector)
    Rect(x, y, wh[1], wh[2])
end
function Rect(xy::FixedVector, wh::FixedVector)
    Rect(xy[1], xy[2], wh[1], wh[2])
end

function register_drag_zoom(cam, screen, key = GLFW.MOUSE_BUTTON_LEFT)
    @materialize mouseposition, mouse_buttons_pressed = screen.inputs
    @materialize mouse_button_down, mouse_button_released = screen.inputs

    is_dragging = false
    rect = Rect(0,0,0,0)
    dragged_rect = foldp(
            (is_dragging, rect),
            mouse_buttons_pressed, mouseposition
        ) do v0, m_pressed, m_pos
        was_dragging, rect = v0
        keypressed = (length(m_pressed) == 1) && (key in m_pressed)
        p = imagespace(m_pos, cam)
        if was_dragging
            wh = p - minimum(rect)
            rect = Rect(minimum(rect), wh)
            if keypressed # was dragging and still dragging
                return true, rect
            else
                return false, rect # anything else will stop the dragging
            end
        elseif keypressed # was not dragging, but now key is pressed
            return true, Rect(p, 0, 0)
        end
        return v0
    end
    lw = 2f0
    rect_vis = visualize(
        map(x-> AABB{Float32}(last(x)), dragged_rect), :lines,
        visible = map(first, dragged_rect),
        camera = :fixed_pixel,
        #pattern = [0.0f0, lw, 2lw, 3lw, 4lw],
        thickness = lw,
        color = RGBA(0.7f0, 0.7f0, 0.7f0, 0.4f0)
    )
    _view(rect_vis, screen, camera = cam)
    preserve(foldp(first(value(dragged_rect)), dragged_rect) do v0, d_r
						 if !d_r[1] && v0 # just switched from dragged to no dragg
							 if d_r[2].w>0.0 
								 center!(cam, AABB{Float32}(d_r[2]))
							 else
								 center!(cam, AABB{Float32}(value(screen.area))) #reset to original camera
							 end
						 end
        d_r[1]
    end)
    rect_vis.children[]
end

#function register_pan(cam, screen)
#    @materialize mouseposition, mouse_buttons_pressed = screen.inputs
#    @materialize mouse_button_down, mouse_button_released,scroll = screen.inputs
#		fscroll = droprepeats(map(Vec2f0, scroll))
#		pan = foldp(+, Vec2f0(0.0),  fscroll)
#		preserve(map(pan) do _pan
#					 center!(cam, AABB{Float32}
#end


end#moduel
