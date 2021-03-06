function [tot_plots] = plot_weights(pca_weights, ymax_scale, color_struct, ...
        sub_rows, sub_cols, plot_counter, plot_increment, font_size)
    %TODO rename to plot_feature_weights()
    %TODO add figure to parameters

    y_max = max(max(pca_weights)) + (ymax_scale * max(max(pca_weights)));
    y_min = min(min(pca_weights));
    if max(max(pca_weights)) == y_min
        y_min = -y_min;
    end
    [~, tot_components] = size(pca_weights);
    unique_ch_group = fieldnames(color_struct);
    for comp_i = 1:tot_components
        comp_weights = pca_weights(:, comp_i);
        scrollsubplot(sub_rows, sub_cols, plot_counter);
        hold on
        if tot_components == 0
            continue
        end
        for ch_group_i = 1:numel(unique_ch_group)
            ch_group = unique_ch_group{ch_group_i};
            reg_i = color_struct.(ch_group).indices;
            bar(reg_i, comp_weights(reg_i), ...
                'FaceColor', color_struct.(ch_group).color, ...
                'EdgeColor', 'none');
        end
        if numel(unique_ch_group) > 1
            lg = legend(unique_ch_group);
            legend('boxoff');
            lg.Location = 'Best';
            lg.Orientation = 'Horizontal';
        end

        ylim([y_min y_max]);
        xlabel('Electrode #', 'FontSize', font_size);
        ylabel('Coefficient Weight', 'FontSize', font_size);
        sub_title = strrep(['PC ' num2str(comp_i)], '_', ' ');
        title(sub_title)
        hold off
        plot_counter = plot_counter + plot_increment;
    end
    tot_plots = plot_counter - 1;
end