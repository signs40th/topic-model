/*global view, VIS, set_view, topic_hash, d3 */
"use strict";

view.word = function (p) {
    var div = d3.select("div#word_view"),
        word = p.word,
        n = p.n,
        words,
        spec, row_height, width,
        svg, clip,
        scale_x, scale_y, scale_bar,
        gs_t, gs_t_enter, gs_t_label, gs_w, gs_w_enter,
        tx_w;

    // word form setup
    d3.select("form#word_view_form")
        .on("submit", function () {
            d3.event.preventDefault();
            var input_word = d3.select("input#word_input")
                .property("value")
                .toLowerCase();
            set_view("/word/" + input_word);
        });

    // setting word to undefined means: do setup only
    if (p.word === undefined) {
        return;
    }

    div.selectAll("#word_view span.word") // sets header and help
        .text(word);

    div.selectAll("#word_view .none").classed("hidden", p.topics.length !== 0);
    div.select("table#word_topics").classed("hidden", p.topics.length === 0);
    div.select("#word_view_explainer").classed("hidden", p.topics.length === 0);

    words = p.topics.map(function (t, j) {
        var max_weight, ws = p.words[j];
        return ws.map(function (tw, i) {
            if (i === 0) {
                max_weight = tw.weight;
            }
            // normalize weights relative to the weight of the word ranked 1
            return {
                word: tw.word,
                weight: tw.weight / max_weight
            };
        });
    });

    spec = { m: VIS.word_view.m };
    spec.w = d3.select("#view").node().clientWidth || VIS.word_view.w;
    spec.w -= spec.m.left + spec.m.right;
    // adjust svg height so that scroll bar isn't too long
    // and svg isn't so short it clips things weirdly
    spec.h = VIS.word_view.row_height * (p.topics.length + 1);

    row_height = VIS.word_view.row_height;
    svg = view.plot_svg("#word_view_main", spec);
    width = Math.max(spec.w, VIS.word_view.w); // set a min. width for coord sys

    scale_x = d3.scale.linear()
        .domain([0, n])
        .range([0, width]);
    scale_y = d3.scale.linear()
        .domain([0, Math.max(1, p.topics.length - 1)])
        .range([row_height, row_height * (Math.max(p.topics.length, 1) + 1)]);
    scale_bar = d3.scale.linear()
        .domain([0, 1])
        .range([0, row_height / 2]);

    clip = d3.select("#word_view_clip");
    if (clip.size() === 0) {
        clip = d3.select("#word_view svg").append("clipPath")
            .attr("id", "word_view_clip");
        clip.append("rect");
    }

    // no transition, just set the clipping to spec
    clip.select("rect")
        .attr("x", -spec.m.left)
        .attr("y", -spec.m.top)
        .attr("width", spec.w + spec.m.left + spec.m.right)
        .attr("height", spec.h + spec.m.top + spec.m.bottom);

    svg.attr("clip-path", "url(#word_view_clip)");

    gs_t = svg.selectAll("g.topic")
        .data(p.topics, function (t) { return t.topic; } );

    // transition: update only
    gs_t.transition().duration(1000)
        .attr("transform", function (t, i) {
            return "translate(0," + scale_y(i) + ")";
        });

    gs_t_enter = gs_t.enter().append("g").classed("topic", true)
        .attr("transform", function (t, i) {
            return "translate(0," + scale_y(i) + ")";
        })
        .style("opacity", 0);

    // TODO refine transition timings

    if (!VIS.ready.word || view.updating()) {
        // if this is the first load or a refresh, we don't want a fade-in
        d3.selectAll("g.topic").style("opacity", 1);
    } else {
        d3.transition().duration(1000)
            .ease("linear")
            .each("end", function () {
                d3.selectAll("g.topic").style("opacity", 1);
            });
    }
    
    // and move exit rows out of the way
    gs_t.exit().transition()
        .duration(2000)
        .attr("transform", "translate(0," +
                row_height * (n + gs_t.exit().size()) + ")")
        .remove();

    gs_t_enter.append("rect")
        .classed("interact", true)
        .attr({
            x: -spec.m.left,
            y: -row_height,
            width: spec.m.left,
            height: row_height
        })
        .on("click", function (t) {
            set_view(topic_hash(t.topic));
        });
                
    gs_t_label = gs_t.selectAll("text.topic")
        .data(function (t, j) {
            var ws = view.topic.label.words({
                t: t.topic,
                name: p.names[j]
            });
            return ws.map(function (w, k) {
                return {
                    word: w,
                    y: -row_height / 2 -
                        (ws.length / 2 - k - 1) * VIS.word_view.topic_label_leading
                };
            }); 
        }, function (w, j) { return w.word + String(j); });

    gs_t_label.enter().append("text").classed("topic", true);
    gs_t_label.exit().remove();

    gs_t_label
        .attr("x", -VIS.word_view.topic_label_padding)
        .attr("y", function (w) {
            return w.y;
        })
        .text(function (w) { return w.word; })
        .classed("merged_topic_sep", function (w) {
            return w.word === "or";
        });

    gs_w = gs_t.selectAll("g.word")
        .data(function (t, i) { return words[i]; },
                function (d) { return d.word; });

    gs_w_enter = gs_w.enter().append("g").classed("word", true);

    gs_w_enter.append("text")
        .attr("transform", "rotate(-45)");

    gs_w_enter.append("rect")
        .classed("proportion", true)
        .attr({ x: 0, y: 0 })
        .attr("width", width / (2 * n))
        .attr("height", function (d) {
            return scale_bar(d.weight);
        });

    gs_w.selectAll("text")
        .text(function (d) { return d.word; });

    gs_w.selectAll("text, rect")
        .on("click", function (d) {
            set_view("/word/" + d.word);
        })
        .on("mouseover", function () {
            d3.select(this.parentNode).classed("hover", true);
        })
        .on("mouseout", function () {
            d3.select(this.parentNode).classed("hover", false);
        });

    gs_w.classed("selected_word", function (d) {
        return d.word === word;
    });

    gs_w_enter.attr("transform", function (d, j) {
        return "translate(" + scale_x(j) + ",-" + row_height / 2 + ")";
    })
        .attr("opacity", (VIS.ready.word && !view.updating()) ? 0 : 1);
    // pre-empting fade-in on first load or refresh

    // update g positions for word/bars
    tx_w = gs_w.transition()
        .duration(2000)
        .attr("transform", function (d, j) {
            return "translate(" + scale_x(j) + ",-" + row_height / 2 + ")";
        })
        .attr("opacity", 1);

    // update word label positions
    tx_w.selectAll("text").attr("x", width / (4 * n));

    // update bar widths
    tx_w.selectAll("rect")
        .attr("width", width / (2 * n))
        .attr("height", function (d) {
            return scale_bar(d.weight);
        });
    // and move exit words out of the way
    gs_w.exit().transition().delay(1000).remove();

    VIS.ready.word = true;
    return true;
    // (later: time graph)
};
