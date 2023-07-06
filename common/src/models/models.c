/*
 * Copyright 2021 The CFU-Playground Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "models/models.h"

#include <stdio.h>

#include "menu.h"
#include "models/hps_model/hps_model.h"
#include "models/magic_wand/magic_wand.h"
#include "models/micro_speech/micro_speech.h"
#include "models/mlcommons_tiny_v01/anomd/anomd.h"
#include "models/mlcommons_tiny_v01/imgc/imgc.h"
#include "models/mlcommons_tiny_v01/kws/kws.h"
#include "models/mlcommons_tiny_v01/vww/vww.h"
#include "models/mnv2/mnv2.h"
#include "models/pdti8/pdti8.h"

// My models include anchor
#include "models/cnn_1d_v012_radioml/cnn_1d_v012_radioml.h"
#include "models/simc_3_MIXED_v2/simc_3_MIXED_v2.h"
#include "models/simc_3_MIXED_v2_no_quant/simc_3_MIXED_v2_no_quant.h"
#include "models/sine/sine.h"

inline void no_menu() {}

// Automatically incrementing compile time constant character.
// Used for avoiding selection character collisions in the menu.
#define STARTING_SEL_CHAR 0x31  // '1'
#define AUTO_INC_CHAR __COUNTER__ + STARTING_SEL_CHAR

static struct Menu MENU = {
    "TfLM Models",
    "models",
    {

// My_models_anchor
#if defined(INCLUDE_MODEL_CNN_1D_V012_RADIOML) || defined(INCLUDE_ALL_TFLM_EXAMPLES)
        MENU_ITEM(AUTO_INC_CHAR, "cnn_1d_v012_radioml", cnn_1d_v012_radioml_menu),
#endif
#if defined(INCLUDE_MODEL_SIMC_3_MIXED_V2_NO_QUANT) || defined(INCLUDE_ALL_TFLM_EXAMPLES)
        MENU_ITEM(AUTO_INC_CHAR, "simc_3_MIXED_v2_no_quant", simc_3_MIXED_v2_no_quant_menu),
#endif
#if defined(INCLUDE_MODEL_SIMC_3_MIXED_V2) || defined(INCLUDE_ALL_TFLM_EXAMPLES)
        MENU_ITEM(AUTO_INC_CHAR, "Signal modulation classification model 3", simc_3_MIXED_v2_menu),
#endif  
#if defined(INCLUDE_MODEL_SINE) || defined(INCLUDE_ALL_TFLM_EXAMPLES)
        MENU_ITEM(AUTO_INC_CHAR, "Primitive sine model", sine_menu),
#endif
/*****************************************************/

#if defined(INCLUDE_MODEL_PDTI8) || defined(INCLUDE_ALL_TFLM_EXAMPLES)
        MENU_ITEM(AUTO_INC_CHAR, "Person Detection int8 model", pdti8_menu),
#endif

#if defined(INCLUDE_MODEL_MICRO_SPEECH) || defined(INCLUDE_ALL_TFLM_EXAMPLES)
        MENU_ITEM(AUTO_INC_CHAR, "Micro Speech", micro_speech_menu),
#endif
#if defined(INCLUDE_MODEL_MAGIC_WAND) || defined(INCLUDE_ALL_TFLM_EXAMPLES)
        MENU_ITEM(AUTO_INC_CHAR, "Magic Wand", magic_wand_menu),
#endif
#if defined(INCLUDE_MODEL_MNV2)
        MENU_ITEM(AUTO_INC_CHAR, "Mobile Net v2 models", mnv2_menu),
#endif
#if defined(INCLUDE_MODEL_HPS)
        MENU_ITEM(AUTO_INC_CHAR, "HPS models", hps_model_menu),
#endif
#if defined(INLCUDE_MODEL_MLCOMMONS_TINY_V01_ANOMD)
        MENU_ITEM(AUTO_INC_CHAR, "MLCommons Tiny V0.1 Anomaly Detection",
                  mlcommons_tiny_v01_anomd_menu),
#endif
#if defined(INLCUDE_MODEL_MLCOMMONS_TINY_V01_IMGC)
        MENU_ITEM(AUTO_INC_CHAR, "MLCommons Tiny V0.1 Image Classification",
                  mlcommons_tiny_v01_imgc_menu),
#endif
#if defined(INLCUDE_MODEL_MLCOMMONS_TINY_V01_KWS)
        MENU_ITEM(AUTO_INC_CHAR, "MLCommons Tiny V0.1 Keyword Spotting",
                  mlcommons_tiny_v01_kws_menu),
#endif
#if defined(INLCUDE_MODEL_MLCOMMONS_TINY_V01_VWW)
        MENU_ITEM(AUTO_INC_CHAR, "MLCommons Tiny V0.1 Visual Wake Words",
                  mlcommons_tiny_v01_vww_menu),
#endif
#if AUTO_INC_CHAR == STARTING_SEL_CHAR
        MENU_ITEM('!', "No models selected! Check defines in Makefile!",
                  no_menu),
#endif
        MENU_END,
    },
};

#undef AUTO_INC_CHAR
#undef STARTING_SEL_CHAR

// For integration into menu system
void models_menu() { menu_run(&MENU); }
