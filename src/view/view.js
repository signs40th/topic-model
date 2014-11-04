/*global VIS, d3, window */
"use strict";
var view = (function () {

    var that = { },
        my = {
            updating: false
        },
        updating,
        dirty,
        loading,
        calculating,
        error,
        warning,
        tooltip,
        append_weight_tds,
        plot_svg,
        append_svg,
        scroll_top,
        scroll_origin;

    updating = function (flag) {
        if (typeof flag === "boolean") {
            my.updating = flag;
        }
        return my.updating;
    };
    that.updating = updating;

    // TODO get rid of updating(), use dirty() everywhere
    dirty = function (key, flag) {
        if (!my.dirty) {
            my.dirty = d3.set();
        }
        if (flag === undefined) {
            return my.dirty.has(key);
        }

        // otherwise
        if (flag) {
            my.dirty.add(key);
        } else {
            my.dirty.remove(key);
        }
        return flag;
    };
    that.dirty = dirty;

    loading = function (flag) {
        d3.select("#working_icon").classed("invisible", !flag);
    };
    that.loading = loading;

    calculating = function (sel, flag) {
        d3.select("#working_icon").classed("invisible", !flag);
        d3.selectAll(sel + " .calc").classed("hidden", !flag);
        d3.selectAll(sel + " .calc-done").classed("hidden", flag);
    };
    that.calculating = calculating;

    error = function (msg) {
        d3.select("div#error")
            .classed("hidden", false)
            .append("p").text(msg);

        this.loading(false);
        VIS.error = true;
    };
    that.error = error;

    warning = function (msg) {
        d3.select("div#warning")
            .classed("hidden", false)
            .append("p").text(msg);
    };
    that.warning = warning;

    // singleton tooltip
    tooltip = function () {
        var tt = my.tooltip;

        // does it already exist?
        if (tt) {
            return tt;
        }

        // otherwise, initialize
        tt = {
            offset: VIS.tooltip.offset
        };

        tt.div = d3.select("body").append("div")
            .attr("id", "tooltip")
            .classed("bar_tooltip", true);
        tt.container = d3.select("body").node();

        tt.div.append("p");

        tt.update_pos = function () {
            var mouse_pos = d3.mouse(this.container);
            this.div.style({
                    left: (mouse_pos[0] + this.offset.x) + 'px',
                    top: (mouse_pos[1] + this.offset.y) + 'px',
                    position: "absolute"
                });
        };
        tt.text = function (text) {
            this.div.select("p").text(text);
        };
        tt.show = function () {
            this.div.classed("hidden", false);
        };
        tt.hide = function () {
            this.div.classed("hidden", true);
        };

        my.tooltip = tt;
        return tt;
    };
    that.tooltip = tooltip;

    append_weight_tds = function (sel, f) {
        sel.append("td").classed("weight", true)
            .append("div")
                .classed("proportion", true)
                .style("margin-left", function (w) {
                    return d3.format(".1%")(1 - f(w));
                })
                .append("span")
                    .classed("proportion", true)
                    .html("&nbsp;");
    };
    that.append_weight_tds = append_weight_tds;

    plot_svg = function (selector, spec) {
        var g;

        if (!VIS.svg) {
            VIS.svg = d3.map();
        }
        if (VIS.svg.has(selector)) {
            g = VIS.svg.get(selector);
            d3.select(selector + " svg")
                .attr("width", spec.w + spec.m.left + spec.m.right)
                .attr("height", spec.h + spec.m.top + spec.m.bottom);

            g.attr("transform",
                    "translate(" + spec.m.left + "," + spec.m.top + ")");
        } else {
            g = append_svg(d3.select(selector), spec);
            VIS.svg.set(selector, g);
        }
        return g;
    };
    that.plot_svg = plot_svg;

    append_svg = function (selection, spec) {
        // mbostock margin convention
        // http://bl.ocks.org/mbostock/3019563
        return selection.append("svg")
                .attr("width", spec.w + spec.m.left + spec.m.right)
                .attr("height", spec.h + spec.m.top + spec.m.bottom)
            // g element passes on xform to all contained elements
            .append("g")
                .attr("transform",
                      "translate(" + spec.m.left + "," + spec.m.top + ")");
    };
    that.append_svg = append_svg;

    scroll_top = function() {
        window.scrollTo(window.scrollX, 0);
    };
    that.scroll_top = scroll_top;

    scroll_origin = function() {
        window.scrollTo(0, 0);
    };
    that.scroll_origin = scroll_origin;

    return that;
}());


