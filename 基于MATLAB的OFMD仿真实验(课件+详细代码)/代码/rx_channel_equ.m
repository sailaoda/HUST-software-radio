function [data_syms_out, pilot_syms_out] = rx_channel_equ(freq_data_syms, freq_pilot_syms, ...
   channel_est, sim_options)

global sim_consts;

% remove extra dimension from matrices, if rx diversity is not used
freq_data_syms = squeeze(freq_data_syms);
freq_pilot_syms = squeeze(freq_pilot_syms);

% Data symbols channel correction
chan_corr_mat = repmat(channel_est(sim_consts.DataSubcPatt), 1, size(freq_data_syms,2));
freq_data_syms = freq_data_syms.*conj(chan_corr_mat);
chan_corr_mat = repmat(channel_est(sim_consts.PilotSubcPatt), 1, size(freq_pilot_syms,2));
freq_pilot_syms = freq_pilot_syms.*conj(chan_corr_mat);

% Amplitude normalization
chan_sq_amplitude = sum(abs(channel_est(sim_consts.DataSubcPatt,:)).^2, 2);
chan_sq_amplitude_mtx = repmat(chan_sq_amplitude,1, size(freq_data_syms,2));

data_syms_out = freq_data_syms./chan_sq_amplitude_mtx;

chan_sq_amplitude = sum(abs(channel_est(sim_consts.PilotSubcPatt,:)).^2, 2);
chan_sq_amplitude_mtx = repmat(chan_sq_amplitude,1, size(freq_pilot_syms,2));
pilot_syms_out = freq_pilot_syms./chan_sq_amplitude_mtx;


