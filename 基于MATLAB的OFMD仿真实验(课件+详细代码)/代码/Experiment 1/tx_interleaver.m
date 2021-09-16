% Interleaver

function interleaved_bits = tx_interleaver(in_bits, fftlen, modulate_level)

interleaver_depth = fftlen * modulate_level;
num_symbols = length(in_bits)/interleaver_depth;
distance = interleaver_depth/2;
%distance = 16;

% Get interleaver pattern for symbols
n_syms_per_ofdm_sym = fftlen;
s = max([interleaver_depth/n_syms_per_ofdm_sym/2 1]);
intlvr_patt = interleaver_depth/distance*rem(0:interleaver_depth-1,distance) + floor((0:interleaver_depth-1)/distance);
perm_patt = s*floor(intlvr_patt/s)+ ...
   mod(intlvr_patt+interleaver_depth-floor(distance*intlvr_patt/interleaver_depth),s);
single_intlvr_patt = perm_patt+1;

% Generate intereleaver pattern for the whole packet
intlvr_patt = interleaver_depth*ones(interleaver_depth, num_symbols);
intlvr_patt = intlvr_patt*diag(0:num_symbols-1);
intlvr_patt = intlvr_patt+repmat(single_intlvr_patt', 1, num_symbols);
intlvr_patt = intlvr_patt(:);

% Perform interleaving
interleaved_bits(intlvr_patt) = in_bits;
