### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Functions for plotting using the Winston package ###

### Generic Map Plot ###
function plotMap(nodes;
                 highways=nothing,
                 buildings=nothing,
                 features=nothing,
                 bounds=nothing,
                 intersections=nothing,
                 roadways=nothing,
                 cycleways=nothing,
                 walkways=nothing,
                 feature_classes=nothing,
                 building_classes=nothing,
                 route=nothing,
                 highway_style::Style=Style(0x007CFF, 1.5, "-"),
                 building_style::Style=Style(0x000000, 1, "-"),
                 feature_style=Style(0xCC0000, 2.5, "."),
                 route_style=Style(0xFF0000, 3, "-"),
                 intersection_style::Style=Style(0x000000, 3, "."),
                 width::Integer=500,
                 fontsize::Integer=4,
                 realtime::Bool=false)

    # Check if bounds type is correct
    if bounds != nothing
        if typeof(bounds) != Bounds
            println("[OpenStreetMap.jl] Warning: Input argument <bounds> in plotMap() unused due to incorrect type.")
            println("[OpenStreetMap.jl] Required type: Bounds")
            println("[OpenStreetMap.jl] Current type: $(typeof(bounds))")
            bounds = nothing
        end
    end

    # Check input node type and compute plot height accordingly
    height = width
    if typeof(nodes) == Dict{Int,LLA}
        xlab = "Longitude (deg)"
        ylab = "Latitude (deg)"

        if bounds != nothing
            aspect_ratio = getAspectRatio(bounds)
            height = int(height / aspect_ratio)
        end
    elseif typeof(nodes) == Dict{Int,ENU}
        xlab = "East (m)"
        ylab = "North (m)"

        # Waiting for Winston to add capability to force equal scales. For now:
        if bounds != nothing
            xrange = bounds.max_lon - bounds.min_lon
            yrange = bounds.max_lat - bounds.min_lat
            aspect_ratio = xrange / yrange
            height = int(width / aspect_ratio)
        end
    else
        println("[OpenStreetMap.jl] ERROR: Input argument <nodes> in plotMap() has unsupported type.")
        println("[OpenStreetMap.jl] Required type: Dict{Int,LLA} OR Dict{Int,ENU}")
        println("[OpenStreetMap.jl] Current type: $(typeof(nodes))")
        return
    end

    # Create the figure
    fignum = Winston.figure(name="OpenStreetMap Plot", width=width, height=height)
    p = Winston.FramedPlot("xlabel",xlab,"ylabel",ylab)

    # Limit plot to specified bounds
    if bounds != nothing
        Winston.xlim(bounds.min_lon, bounds.max_lon)
        Winston.ylim(bounds.min_lat, bounds.max_lat)
        p = Winston.FramedPlot("xlabel",xlab,"ylabel",ylab,xrange=(bounds.min_lon,bounds.max_lon),yrange=(bounds.min_lat,bounds.max_lat))
    end

    # Iterate over all buildings and draw
    if buildings != nothing
        if typeof(buildings) == Dict{Int,Building}
            if building_classes != nothing && typeof(building_classes) == Dict{Int,Int}
                if typeof(building_style) == Dict{Int,Style}
                    drawWayLayer(p, nodes, buildings, building_classes, building_style, realtime)
                else
                    drawWayLayer(p, nodes, buildings, building_classes, LAYER_BUILDINGS, realtime)
                end
            else
                for (key, building) in buildings
                    # Get coordinates of all nodes for object
                    coords = getNodeCoords(nodes, building.nodes)

                    # Add line(s) to plot
                    drawNodes(p, coords, building_style, realtime)
                end
            end
        else
            println("[OpenStreetMap.jl] Warning: Input argument <buildings> in plotMap() could not be plotted.")
            println("[OpenStreetMap.jl] Required type: Dict{Int,Building}")
            println("[OpenStreetMap.jl] Current type: $(typeof(buildings))")
        end
    end

    # Iterate over all highways and draw
    if highways != nothing
        if typeof(highways) == Dict{Int,Highway}
            if roadways != nothing || cycleways != nothing || walkways != nothing
                if roadways != nothing
                    if typeof(highway_style) == Dict{Int,Style}
                        drawWayLayer(p, nodes, highways, roadways, highway_style, realtime)
                    else
                        drawWayLayer(p, nodes, highways, roadways, LAYER_STANDARD, realtime)
                    end
                end
                if cycleways != nothing
                    if typeof(highway_style) == Dict{Int,Style}
                        drawWayLayer(p, nodes, highways, cycleways, highway_style, realtime)
                    else
                        drawWayLayer(p, nodes, highways, cycleways, LAYER_CYCLE, realtime)
                    end
                end
                if walkways != nothing
                    if typeof(highway_style) == Dict{Int,Style}
                        drawWayLayer(p, nodes, highways, walkways, highway_style, realtime)
                    else
                        drawWayLayer(p, nodes, highways, walkways, LAYER_PED, realtime)
                    end
                end
            else
                for (key, highway) in highways
                    # Get coordinates of all nodes for object
                    coords = getNodeCoords(nodes, highway.nodes)

                    # Add line(s) to plot
                    drawNodes(p, coords, highway_style, realtime)
                end
            end
        else
            println("[OpenStreetMap.jl] Warning: Input argument <highways> in plotMap() could not be plotted.")
            println("[OpenStreetMap.jl] Required type: Dict{Int,Highway}")
            println("[OpenStreetMap.jl] Current type: $(typeof(highways))")
        end
    end

    # Iterate over all features and draw
    if features != nothing
        if typeof(features) == Dict{Int,Feature}
            if feature_classes != nothing && typeof(feature_classes) == Dict{Int,Int}
                if typeof(feature_style) == Style
                    drawFeatureLayer(p, nodes, features, feature_classes, LAYER_FEATURES, realtime)
                elseif typeof(feature_style) == Dict{Int,Style}
                    drawFeatureLayer(p, nodes, features, feature_classes, feature_style, realtime)
                end
            else
                coords = getNodeCoords(nodes, collect(keys(features)))

                # Add feature point(s) to plot
                drawNodes(p, coords, feature_style, realtime)
            end
        else
            println("[OpenStreetMap.jl] Warning: Input argument <features> in plotMap() could not be plotted.")
            println("[OpenStreetMap.jl] Required type: Dict{Int,Feature}")
            println("[OpenStreetMap.jl] Current type: $(typeof(features))")
        end
    end

    # Draw route
    if route != nothing
        if typeof(route) == Vector{Int}
            # Get coordinates of all nodes for route
            coords = getNodeCoords(nodes, route)

            # Add line(s) to plot
            drawNodes(p, coords, route_style, realtime)
        elseif typeof(route) == Vector{Vector{Int}}
            for k = 1:length(route)
                coords = getNodeCoords(nodes, route[k])
                if typeof(route_style) == Vector{Style}
                    drawNodes(p, coords, route_style[k], realtime)
                elseif typeof(route_style) == Style
                    drawNodes(p, coords, route_style, realtime)
                else
                    println("[OpenStreetMap.jl] Warning: Route in plotMap() could not be plotted.")
                    println("[OpenStreetMap.jl] Required <route_style> type: Style or Vector{Style}")
                    println("[OpenStreetMap.jl] Current type: $(typeof(route_style))")
                end
            end
        else
            println("[OpenStreetMap.jl] Warning: Input argument <route> in plotMap() could not be plotted.")
            println("[OpenStreetMap.jl] Required type: Vector{Int64}")
            println("[OpenStreetMap.jl] Current type: $(typeof(route))")
        end
    end

    # Iterate over all intersections and draw
    if intersections != nothing
        if typeof(intersections) == Dict{Int,Intersection}
            coords = Array(Float64, length(intersections), 2)
            k = 1
            for key in keys(intersections)
                coords[k, :] = getNodeCoords(nodes, key)
                k += 1
            end

            # Add intersection(s) to plot
            drawNodes(p, coords, intersection_style, realtime)
        else
            println("[OpenStreetMap.jl] Warning: Input argument <intersections> in plotMap() could not be plotted.")
            println("[OpenStreetMap.jl] Required type: Dict{Int,Intersection}")
            println("[OpenStreetMap.jl] Current type: $(typeof(intersections))")
        end
    end

    Winston.setattr(p.x1,"label_style",[:fontsize=>fontsize])
    Winston.setattr(p.y1,"label_style",[:fontsize=>fontsize])
    Winston.setattr(p.x1,"ticklabels_style",[:fontsize=>fontsize])
    Winston.setattr(p.y1,"ticklabels_style",[:fontsize=>fontsize])

    display(p)

    # Return figure object (enables further manipulation)
    return p
end


### Draw layered Map ###
function drawWayLayer(p::Winston.FramedPlot, nodes::Dict, ways, classes, layer, realtime=false)
    for (key, class) in classes
        # Get coordinates of all nodes for object
        coords = getNodeCoords(nodes, ways[key].nodes)

        # Add line(s) to plot
        drawNodes(p, coords, layer[class], realtime)
    end
end


### Draw layered features ###
function drawFeatureLayer(p::Winston.FramedPlot, nodes::Dict, features, classes, layer, realtime=false)

    for id in unique(values(classes))
        ids = Int[]

        for (key, class) in classes
            if class == id
                push!(ids, key)
            end
        end

        # Get coordinates of node for object
        coords = getNodeCoords(nodes, ids)

        # Add point to plot
        drawNodes(p, coords, layer[id], realtime)
    end
end


### Get coordinates of lists of nodes ###
# Nodes in LLA coordinates
function getNodeCoords(nodes::Dict{Int,LLA}, id_list)
    coords = Array(Float64, length(id_list), 2)

    for k = 1:length(id_list)
        loc = nodes[id_list[k]]
        coords[k, 1] = loc.lon
        coords[k, 2] = loc.lat
    end

    return coords
end


# Nodes in ENU coordinates
function getNodeCoords(nodes::Dict{Int,ENU}, id_list)
    coords = Array(Float64, length(id_list), 2)

    for k = 1:length(id_list)
        loc = nodes[id_list[k]]
        coords[k, 1] = loc.east
        coords[k, 2] = loc.north
    end

    return coords
end


### Draw a line between all points in a coordinate list ###
function drawNodes(p::Winston.FramedPlot, coords, style="k-", width=1, realtime=false)
    x = coords[:, 1]
    y = coords[:, 2]
    if length(x) > 1
        if realtime
            display(Winston.plot(p, x, y, style, linewidth=width))
        else
            Winston.plot(p, x, y, style, linewidth=width)
        end
    end
    nothing
end


### Draw a line between all points in a coordinate list given Style object ###
function drawNodes(p::Winston.FramedPlot, coords, line_style::Style, realtime=false)
    x = coords[:, 1]
    y = coords[:, 2]
    if length(x) > 1
        if realtime
            display(Winston.plot(p, x, y, line_style.spec, color=line_style.color, linewidth=line_style.width))
        else
            Winston.plot(p, x, y, line_style.spec, color=line_style.color, linewidth=line_style.width)
        end
    end
    nothing
end


### Compute approximate "aspect ratio" at mean latitude ###
function getAspectRatio(bounds::Bounds)
    c_adj = cosd(mean([bounds.min_lat, bounds.max_lat]))
    range_lat = bounds.max_lat - bounds.min_lat
    range_lon = bounds.max_lon - bounds.min_lon

    return range_lon * c_adj / range_lat
end
