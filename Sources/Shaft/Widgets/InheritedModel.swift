/// An ``InheritedWidget`` that's intended to be used as the base class for models
/// whose dependents may only depend on one part or "aspect" of the overall
/// model.
///
/// An inherited widget's dependents are unconditionally rebuilt when the
/// inherited widget changes per ``InheritedWidget/updateShouldNotify``. This
/// widget is similar except that dependents aren't rebuilt unconditionally.
///
/// Widgets that depend on an ``InheritedModel`` qualify their dependence with a
/// value that indicates what "aspect" of the model they depend on. When the
/// model is rebuilt, dependents will also be rebuilt, but only if there was a
/// change in the model that corresponds to the aspect they provided.
///
/// The type parameter `T` is the type of the model aspect objects.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ml5uefGgkaA}
///
/// Widgets create a dependency on an ``InheritedModel`` with a static method:
/// ``InheritedModel/inheritFrom``. This method's `context` parameter defines the
/// subtree that will be rebuilt when the model changes. Typically the
/// `inheritFrom` method is called from a model-specific static `maybeOf` or
/// `of` methods, a convention that is present in many Flutter framework classes
/// which look things up. For example:
///
/// ```swift
/// class MyModel: InheritedModel<String> {
///   init(key: Key? = nil, child: Widget) {
///     super.init(key: key, child: child)
///   }
///
///   // ...
///   static func maybeOf(context: BuildContext, aspect: String? = nil) -> MyModel? {
///     return InheritedModel.inheritFrom<MyModel>(context, aspect: aspect)
///   }
///
///   // ...
///   static func of(context: BuildContext, aspect: String? = nil) -> MyModel {
///     guard let result = maybeOf(context: context, aspect: aspect) else {
///       fatalError("Unable to find an instance of MyModel...")
///     }
///     return result
///   }
/// }
/// ```
///
/// Calling `MyModel.of(context, 'foo')` or `MyModel.maybeOf(context,
/// 'foo')` means that `context` should only be rebuilt when the `foo` aspect of
/// `MyModel` changes. If the `aspect` is null, then the model supports all
/// aspects.
///
/// In the previous example the dependencies checked by
/// ``updateShouldNotifyDependent`` are just the aspect strings passed to
/// `dependOnInheritedWidgetOfExactType`. They're represented as a ``Set`` because
/// one Widget can depend on more than one aspect of the model. If a widget
/// depends on the model but doesn't specify an aspect, then changes in the
/// model will cause the widget to be rebuilt unconditionally.
///
/// See also:
///
/// * ``InheritedWidget``, an inherited widget that only notifies dependents when
///   its value is different.
/// * ``InheritedNotifier``, an inherited widget whose value can be a
///   [Listenable], and which will notify dependents whenever the value sends
///   notifications.
public protocol InheritedModel<AspectType>: InheritedWidget {
    associatedtype AspectType: Hashable

    /// Returns true if this model supports the given [aspect].
    ///
    /// Returns true by default: this model supports all aspects.
    ///
    /// Subclasses may override this method to indicate that they do not support
    /// all model aspects. This is typically done when a model can be used
    /// to "shadow" some aspects of an ancestor.
    func isSupportedAspect(_ aspect: Any) -> Bool

    /// Return true if the changes between this model and [oldWidget] match any
    /// of the [dependencies].
    func updateShouldNotifyDependent(_ oldWidget: ProxyWidget, _ dependencies: Set<AspectType>)
        -> Bool
}

extension InheritedModel {
    public func createElement() -> Element {
        return InheritedModelElement<AspectType>(self)
    }

    public func isSupportedAspect(_ aspect: Any) -> Bool {
        return true
    }

    // The [result] will be a list of all of context's type T ancestors concluding
    // with the one that supports the specified model [aspect].
    private static func _findModels<T: InheritedModel>(
        _ type: T.Type,
        context: BuildContext,
        aspect: Any,
        results: inout [InheritedElement]
    ) {
        let model = context.getElementForInheritedWidgetOfExactType(type)
        guard let model = model else {
            return
        }

        results.append(model)

        assert(model.widget is T)
        let modelWidget = model.widget as! T
        if modelWidget.isSupportedAspect(aspect) {
            return
        }

        var modelParent: Element?
        model.visitAncestorElements { ancestor in
            modelParent = ancestor
            return false
        }
        guard let modelParent = modelParent else {
            return
        }

        _findModels(type, context: modelParent, aspect: aspect, results: &results)
    }

    /// Makes [context] dependent on the specified [aspect] of an ``InheritedModel``
    /// of type T.
    ///
    /// When the given [aspect] of the model changes, the [context] will be
    /// rebuilt. The ``updateShouldNotifyDependent`` method must determine if a
    /// change in the model widget corresponds to an [aspect] value.
    ///
    /// The dependencies created by this method target all ``InheritedModel`` ancestors
    /// of type T up to and including the first one for which [isSupportedAspect]
    /// returns true.
    ///
    /// If [aspect] is null this method is the same as
    /// `context.dependOnInheritedWidgetOfExactType<T>()`.
    ///
    /// If no ancestor of type T exists, null is returned.
    public static func inheritFrom<T: InheritedModel>(
        _ type: T.Type,
        context: BuildContext,
        aspect: Any? = nil
    ) -> T? {
        if aspect == nil {
            return context.dependOnInheritedWidgetOfExactType(type)
        }

        // Create a dependency on all of the type T ancestor models up until
        // a model is found for which isSupportedAspect(aspect) is true.
        var models = [InheritedElement]()
        _findModels(type, context: context, aspect: aspect!, results: &models)
        if models.isEmpty {
            return nil
        }

        let lastModel = models.last!
        for model in models {
            let value = context.dependOnInheritedElement(model, aspect: aspect) as! T
            if model === lastModel {
                return value
            }
        }

        assertionFailure()
        return nil
    }

}

/// An [Element] that uses a ``InheritedModel`` as its configuration.
public class InheritedModelElement<T: Hashable>: InheritedElement {
    /// Creates an element that uses the given widget as its configuration.
    public init(_ widget: any InheritedModel<T>) {
        super.init(widget)
    }

    public override func updateDependencies(_ dependent: Element, aspect: Any?) {
        let dependencies = getDependencies(dependent) as? Set<T>
        if dependencies != nil && dependencies!.isEmpty {
            return
        }

        if aspect == nil {
            setDependencies(dependent, Set<T>())
        } else {
            assert(aspect is T)
            var deps = dependencies ?? Set<T>()
            deps.insert(aspect as! T)
            setDependencies(dependent, deps)
        }
    }

    public override func notifyDependent(_ oldWidget: ProxyWidget, _ dependent: Element) {
        let dependencies = getDependencies(dependent) as? Set<T>
        if dependencies == nil {
            return
        }
        if dependencies!.isEmpty
            || (widget as! (any InheritedModel<T>)).updateShouldNotifyDependent(
                oldWidget,
                dependencies!
            )
        {
            dependent.didChangeDependencies()
        }
    }
}
