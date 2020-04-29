
# DictTransform
abstract type AbstractSampleTransform end
abstract type AbstractDictTransform <: AbstractSampleTransform end

struct DictTransformApplyAll <: AbstractDictTransform
    ins::NTuple{N, Symbol} where N
    tfm
end
DictTransformApplyAll(in::Symbol, tfm) = DictTransformApplyAll((in,), tfm);

struct DictTransformCombine <: AbstractDictTransform
    ins::Tuple
    out::Symbol
    tfm
end

struct SampleTransformLambda <: AbstractSampleTransform
    f
end


AbstractDictTransform(ins::NTuple{N, Symbol}, tfm) where N = DictTransformApplyAll(ins, tfm)
AbstractDictTransform(in_::Symbol, tfm) = DictTransformApplyAll((in_,), tfm)
AbstractDictTransform(ins::Tuple, out::Symbol, tfm) = DictTransformCombine(ins, out, tfm)
AbstractDictTransform(in_, out::Symbol, tfm) = DictTransformCombine((in_,), out, tfm)
AbstractDictTransform(f) = SampleTransformLambda(f)


function (st::DictTransformApplyAll)(sample)
    args = Tuple(sample[in_] for in_ in st.ins)
    outs = st.tfm(args)
    for (in_, out) in zip(st.ins, outs)
        sample[in_] = out
    end 
    
    return sample
end

function (st::DictTransformCombine)(sample)
    args = Tuple(sample[in_] for in_ in st.ins)
    sample[st.out] = st.tfm(args...)
    return sample
end

function (st::SampleTransformLambda)(sample) 
    return st.f(sample)
end


struct DictPipeline <: AbstractDictTransform
    sampletransforms::NTuple{N, AbstractSampleTransform} where N
end

DictPipeline(argss::AbstractVector) = DictPipeline(
    Tuple(AbstractDictTransform(args...) for args in argss)
)

(pipeline::DictPipeline)(sample) = foldl((sample, f) -> f(sample), pipeline.sampletransforms; init = sample)


struct XYPipeline <: AbstractSampleTransform
    transformx
    transformy
end

(pipeline::XYPipeline)((x, y)::Tuple) = (pipeline.transformx(x), pipeline.transformy(y))